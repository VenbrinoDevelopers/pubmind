import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

class PubMindAgent {
  PubMindAgent({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.temperature = 0.5,
    this.maxIterations = 100,
    this.maxTokens = 4096,
    this.tools = const [],
  }) {
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

  late final ChatOpenAI _llm;
  final List<ChatMessage> _conversationHistory = [];
  int _totalIterations = 0;

  Future<String> execute({
    required String task,
    required String systemPrompt,
    Map<String, dynamic>? context,
  }) async {
    _conversationHistory.add(ChatMessage.humanText(task));

    int currentTurnIterations = 0;
    bool taskCompleted = false;

    while (currentTurnIterations < maxIterations && !taskCompleted) {
      currentTurnIterations++;
      _totalIterations++;

      final response = await _llm.invoke(
        PromptValue.chat([
          ChatMessage.system(_buildSystemPrompt(systemPrompt, context)),
          ..._conversationHistory
        ]),
      );

      final aiMessage = response.output;
      _conversationHistory.add(aiMessage);

      if (aiMessage.toolCalls.isNotEmpty) {
        final toolResult = await _handleToolCalls(aiMessage.toolCalls);

        if (toolResult.taskCompleted) {
          return toolResult.finalAnswer!;
        }

        _conversationHistory.addAll(toolResult.messages);

        continue;
      }

      return aiMessage.contentAsString;
    }

    if (currentTurnIterations >= maxIterations) {
      return 'I reached the maximum number of iterations ($maxIterations). Try rephrasing your question.';
    }

    return 'Task completed';
  }

  Future<_ToolResult> _handleToolCalls(
      List<AIChatMessageToolCall> toolCalls) async {
    final List<ChatMessage> toolMessages = [];

    for (final toolCall in toolCalls) {
      final toolName = toolCall.name;
      final toolArgs = toolCall.arguments;

      print('Tool name: $toolName');
      print('Tool args: $toolArgs');

      final tool = tools.firstWhereOrNull(
        (t) => t.name == toolName,
      );

      if (tool == null) {
        toolMessages.add(
          ChatMessage.tool(
            toolCallId: toolCall.id,
            content: "I'm sorry, but I don't know how to help with that.",
          ),
        );
        continue;
      }

      final result = await tool.invoke(
        tool.getInputFromJson(toolArgs),
      );

      print('Tool result: $result');

      toolMessages.add(
        ChatMessage.tool(
          toolCallId: toolCall.id,
          content: result.toString(),
        ),
      );

      if (result.toString().startsWith('__TASK_DONE__:')) {
        final answer = result.toString().replaceFirst('__TASK_DONE__:', '');
        return _ToolResult(
          taskCompleted: true,
          finalAnswer: answer,
        );
      }
    }

    return _ToolResult(
      taskCompleted: false,
      messages: toolMessages,
    );
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
    _conversationHistory.clear();
    _totalIterations = 0;
  }

  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  int get iterationCount => _totalIterations;
}

/// Simple struct for tool execution results
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
