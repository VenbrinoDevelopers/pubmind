import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:pubmind/agents/agent.dart';
import 'package:pubmind/agents/prompt/system_prompt.dart';
import 'package:pubmind/agents/tools/compatibility_checker.dart';
import 'package:pubmind/agents/tools/get_package_info.dart';
import 'package:pubmind/agents/tools/install_package.dart';
import 'package:pubmind/agents/tools/read_pub_spec.dart';
import 'package:pubmind/agents/tools/recommendation.dart';
import 'package:pubmind/agents/tools/run_command.dart';
import 'package:pubmind/agents/tools/search_package.dart';
import 'package:pubmind/agents/tools/sequential_thinking.dart';
import 'package:pubmind/agents/tools/task_done.dart';
import 'package:pubmind/commands/base_commands.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/core/command_service.dart';
import 'package:pubmind/utils/logger_utils.dart';
import 'package:pubmind/utils/process_runner.dart';
import 'package:pubmind/utils/response_formatter.dart';

class ChatCommand extends BaseCommand {
  ChatCommand(super.logger) {
    argParser
      ..addOption(
        'model',
        abbr: 'm',
        help: 'OpenAI model to use.',
        defaultsTo: 'gpt-4o-mini',
        allowed: ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo'],
      )
      ..addFlag(
        'with-tools',
        defaultsTo: true,
        help: 'Enable agent tools for package management.',
      );
  }

  @override
  String get name => 'chat';

  @override
  String get description =>
      'Open an interactive chat session with the PubMind AI agent.';

  @override
  String get invocation => 'pubmind chat';

  String get model => argResults?['model'] as String? ?? 'gpt-4o-mini';
  bool get withTools => argResults?['with-tools'] as bool? ?? true;

  PubMindAgent? _agent;
  bool _isRunning = false;

  @override
  Future<int> execute() async {
    _agent = PubMindAgent(
      apiKey: apiKey!,
      model: model,
      temperature: 0.5,
      maxIterations: 100,
      tools: [
        createRecommendPackagesTool(),
        createTaskDoneTool(),
        createSearchPackagesTool(),
        createGetPackageInfoTool(),
        createCheckCompatibilityTool(
          processRunner: ProcessRunner(
              workingDirectory: projectDirectory, verbose: verbose),
          projectDirectory: projectDirectory,
        ),
        createReadPubspecTool(projectDirectory: projectDirectory),
        createSequentialThinkingTool(),
        createInstallPackageTool(
          processRunner: ProcessRunner(
              workingDirectory: projectDirectory, verbose: verbose),
          projectDirectory: projectDirectory,
        ),
        createRunCommandTool(
          commandService: CommandService(
            processRunner: ProcessRunner(
                workingDirectory: projectDirectory, verbose: verbose),
          ),
        ),
      ],
    );

    LoggerUtils.printWelcomeBanner(logger, model, projectDirectory, withTools);
    LoggerUtils.printCommands(logger);

    _isRunning = true;

    ProcessSignal.sigint.watch().listen((_) {
      _handleExit();
    });

    await _chatLoop();

    return ExitCode.success.code;
  }

  Future<void> _chatLoop() async {
    while (_isRunning) {
      stdout.write('${lightCyan.wrap('You')} > ');

      final input = stdin.readLineSync()?.trim();

      if (input == null || input.isEmpty) {
        continue;
      }

      if (input.startsWith('/')) {
        _handleCommand(input);
        continue;
      }
      await _startAiagent(input);
    }
  }

  Future<void> _startAiagent(String message) async {
    logger.info('');
    try {
      final response = await _agent!.execute(
        task: message,
        systemPrompt: SystemPrompts.agent,
        context: {
          'ProjectType': isFlutterProject ? 'Flutter' : 'Dart',
          'project_directory': projectDirectory,
        },
      );

      logger.info('');
      logger.info('${lightGreen.wrap('AI')} > ');
      ResponseFormatter.printFormatted(logger, response);
      logger.info('');
    } catch (e) {
      logger.err('Error: $e');
      logger.info('');
    }
  }

  void _handleCommand(String command) {
    switch (command.toLowerCase()) {
      case '/help':
        logger.info('');
        LoggerUtils.printCommands(logger);
        break;

      case '/clear':
        _agent?.clearHistory();
        logger.success('Conversation history cleared!');
        logger.info('');
        break;

      case '/history':
        _showHistory();
        break;

      case '/exit':
      case '/quit':
        _handleExit();
        break;

      default:
        logger.warn('Unknown command: $command');
        logger.info('Type /help to see available commands.');
        logger.info('');
    }
  }

  void _showHistory() {
    logger.info('');
    logger.info('${lightCyan.wrap('Conversation History:')}');
    logger.info('${darkGray.wrap('─' * 60)}');

    final history = _agent?.conversationHistory ?? [];

    if (history.isEmpty) {
      logger.info('No conversation history yet.');
      logger.info('');
      return;
    }

    for (final message in history) {
      if (message is SystemChatMessage) {
        logger.info(
            '${darkGray.wrap('[System]')} ${message.contentAsString.split('\n').first}...');
      } else if (message is HumanChatMessage) {
        logger.info('${lightCyan.wrap('[You]')} ${message.contentAsString}');
      } else if (message is AIChatMessage) {
        final content = message.contentAsString;
        if (content.isNotEmpty) {
          logger.info('${lightGreen.wrap('[AI]')} $content');
        }
        if (message.toolCalls.isNotEmpty) {
          logger.info(
              '${lightYellow.wrap('[Tools Called]')} ${message.toolCalls.map((t) => t.name).join(', ')}');
        }
      } else if (message is ToolChatMessage) {
        logger.info('${darkGray.wrap('[Tool Result]')} ${message.content}');
      }
    }

    logger.info('${darkGray.wrap('─' * 60)}');
    logger.info('Total messages: ${history.length}');
    logger.info('');
  }

  void _handleExit() {
    logger.info('');
    logger.info('${lightYellow.wrap('👋 Exiting chat...')}');

    if (_agent != null) {
      final iterationCount = _agent!.iterationCount;
      final historySize = _agent!.conversationHistory.length;

      logger.info('');
      logger.info('${darkGray.wrap('Session stats:')}');
      logger.info('  Messages: $historySize');
      logger.info('  Iterations: $iterationCount');
    }

    logger.info('');
    logger.success('Goodbye! 👋');

    _isRunning = false;
    exit(ExitCode.success.code);
  }
}
