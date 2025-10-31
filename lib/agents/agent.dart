import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:mason_logger/mason_logger.dart';

class PubMindAgent {
  PubMindAgent({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.temperature = 0.5,
    this.maxIterations = 100,
    this.maxTokens = 4096,
    this.tools = const [],
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    _llm = ChatOpenAI(
      apiKey: apiKey,
      defaultOptions: ChatOpenAIOptions(
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        tools: tools,
      ),
    );
  }

  final String apiKey;
  final String model;
  final double temperature;
  final int maxIterations;
  final int maxTokens;
  final List<Tool> tools;
  final Logger _logger;

  late final ChatOpenAI _llm;
  final List<ChatMessage> _conversationHistory = [];
  int _totalIterations = 0;

  Future<String> execute({
    required String task,
    required String systemPrompt,
    Map<String, dynamic>? context,
  }) async {
    _logger.info('');
    _logger.info('${lightCyan.wrap('🤖 Starting AI task execution...')}');
    _logger.detail('${darkGray.wrap('Task:')} $task');

    _conversationHistory.add(ChatMessage.humanText(task));

    int currentTurnIterations = 0;
    bool taskCompleted = false;

    while (currentTurnIterations < maxIterations && !taskCompleted) {
      currentTurnIterations++;
      _totalIterations++;

      _logger.info('');
      _logger.info('${darkGray.wrap('─' * 60)}');
      _logger.info(
          '${lightYellow.wrap('🔄 Iteration $currentTurnIterations/$maxIterations')}');

      final progress = _logger.progress('${lightCyan.wrap('Thinking')}');

      try {
        final response = await _llm.invoke(
          PromptValue.chat([
            ChatMessage.system(_buildSystemPrompt(systemPrompt, context)),
            ..._conversationHistory
          ]),
        );

        progress.complete('${lightGreen.wrap('✓')} Response received');

        final aiMessage = response.output;
        _conversationHistory.add(aiMessage);

        if (aiMessage.contentAsString.isNotEmpty) {
          _logger.detail(
              '${darkGray.wrap('AI Response:')} ${aiMessage.contentAsString.substring(0, aiMessage.contentAsString.length > 100 ? 100 : aiMessage.contentAsString.length)}${aiMessage.contentAsString.length > 100 ? '...' : ''}');
        }

        if (aiMessage.toolCalls.isNotEmpty) {
          _logger.info(
              '${lightMagenta.wrap('🔧 Tool calls detected:')} ${aiMessage.toolCalls.length} tool(s)');

          final toolResult = await _handleToolCalls(aiMessage.toolCalls);

          if (toolResult.taskCompleted) {
            _conversationHistory.addAll(toolResult.messages);
            _logger.info('');
            _logger
                .info('${lightGreen.wrap('✓ Task completed successfully!')}');
            _logger.detail(
                '${darkGray.wrap('Total iterations:')} $currentTurnIterations');
            return toolResult.finalAnswer!;
          }

          _conversationHistory.addAll(toolResult.messages);
          continue;
        }

        _logger.info('');
        _logger.info('${lightGreen.wrap('✓ Task completed!')}');
        _logger.detail(
            '${darkGray.wrap('Total iterations:')} $currentTurnIterations');
        return aiMessage.contentAsString;
      } catch (e) {
        progress.fail('${red.wrap('✗')} Error occurred');
        _logger.err('Error in iteration $currentTurnIterations: $e');
        rethrow;
      }
    }

    if (currentTurnIterations >= maxIterations) {
      _logger.warn('${yellow.wrap('⚠')} Maximum iterations reached');
      return 'I reached the maximum number of iterations ($maxIterations). Try rephrasing your question.';
    }

    return 'Task completed';
  }

  Future<_ToolResult> _handleToolCalls(
      List<AIChatMessageToolCall> toolCalls) async {
    final List<ChatMessage> toolMessages = [];

    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      final toolName = toolCall.name;
      final toolArgs = toolCall.arguments;

      _logger.info('');
      _logger.info(
          '  ${lightCyan.wrap('Tool ${i + 1}/${toolCalls.length}:')} ${lightYellow.wrap(toolName)}');
      _logger.detail(
          '  ${darkGray.wrap('Arguments:')} ${_formatToolArgs(toolArgs)}');

      final tool = tools.firstWhereOrNull(
        (t) => t.name == toolName,
      );

      if (tool == null) {
        _logger.warn('  ${yellow.wrap('⚠')} Tool not found: $toolName');
        toolMessages.add(
          ChatMessage.tool(
            toolCallId: toolCall.id,
            content: "I'm sorry, but I don't know how to help with that.",
          ),
        );
        continue;
      }

      final toolProgress =
          _logger.progress('  ${darkGray.wrap('Executing')} $toolName');

      try {
        final result = await tool.invoke(
          tool.getInputFromJson(toolArgs),
        );
        _logger.info('');
        _logger.info('  result: $result');

        toolProgress.complete('  ${lightGreen.wrap('✓')} $toolName completed');

        final resultStr = result.toString();
        if (resultStr.length > 150) {
          _logger.detail(
              '  ${darkGray.wrap('Result:')} ${resultStr.substring(0, 150)}...');
        } else {
          _logger.detail('  ${darkGray.wrap('Result:')} $resultStr');
        }

        toolMessages.add(
          ChatMessage.tool(
            toolCallId: toolCall.id,
            content: resultStr,
          ),
        );

        if (resultStr.startsWith('__TASK_DONE__:')) {
          final answer = resultStr.replaceFirst('__TASK_DONE__:', '');
          _logger.info(
              '  ${lightGreen.wrap('✓ Task completion signal received')}');
          return _ToolResult(
            taskCompleted: true,
            finalAnswer: answer,
            messages: toolMessages,
          );
        }
      } catch (e) {
        toolProgress.fail('  ${red.wrap('✗')} $toolName failed');
        _logger.err('  Error executing tool $toolName: $e');

        toolMessages.add(
          ChatMessage.tool(
            toolCallId: toolCall.id,
            content: 'Error executing tool: $e',
          ),
        );
      }
    }

    return _ToolResult(
      taskCompleted: false,
      messages: toolMessages,
    );
  }

  String _formatToolArgs(Map<String, dynamic> args) {
    if (args.isEmpty) return 'none';

    final formatted = args.entries.map((e) {
      final value = e.value.toString();
      return '${e.key}=${value.length > 50 ? '${value.substring(0, 50)}...' : value}';
    }).join(', ');

    return formatted;
  }

  String _buildSystemPrompt(String basePrompt, Map<String, dynamic>? context) {
    final buffer = StringBuffer(basePrompt);

    if (tools.isNotEmpty) {
      buffer.write('''

INSTRUCTIONS FOR TOOL USAGE:
1. Analyze the task carefully and plan your approach
2. Use the available tools to solve the task
3. You can call multiple tools as needed
4. Think step-by-step (you are $model with reasoning capabilities)
5. When the task is COMPLETELY solved, call "task_done" with your final answer
6. If you cannot solve the task, still call "task_done" and explain why
''');
    }

    if (context != null && context.isNotEmpty) {
      buffer.write('\n\nCONTEXT:\n');
      buffer.write(_formatContext(context));
    }

    return buffer.toString();
  }

  String _formatContext(Map<String, dynamic> context) {
    return context.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  void clearHistory() {
    _logger.info('${lightYellow.wrap('🔄 Clearing conversation history...')}');
    _conversationHistory.clear();
    _totalIterations = 0;
    _logger.detail('${lightGreen.wrap('✓')} History cleared');
  }

  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  int get iterationCount => _totalIterations;
}

class _ToolResult {
  final bool taskCompleted;
  final String? finalAnswer;
  final List<ChatMessage> messages;

  _ToolResult({
    required this.taskCompleted,
    this.finalAnswer,
    this.messages = const [],
  });
}
