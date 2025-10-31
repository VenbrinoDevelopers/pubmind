import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pubmind/commands/config_command.dart';
import 'package:pubmind/commands/chat_commmand.dart';
import 'package:pubmind/utils/logger_utils.dart';

const String version = '1.0.0';

Future<void> main(List<String> arguments) async {
  final logger = Logger();

  final runner = CommandRunner<int>(
    'pubmind',
    '🤖 PubMind - AI-powered package manager for Dart & Flutter',
  )
    ..addCommand(ChatCommand(logger))
    ..addCommand(ConfigCommand(logger))
    ..argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    )
    ..argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging.',
    );

  try {
    final argResults = runner.argParser.parse(arguments);

    if (argResults['version'] == true) {
      logger.info('PubMind version: $version');
      exit(0);
    }

    if (argResults.command == null && arguments.isEmpty) {
      LoggerUtils.printBanner(logger);
      logger.info(runner.usage);
      exit(0);
    }

    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    logger
      ..err(e.message)
      ..info('')
      ..info(e.usage);
    exit(64);
  } catch (e) {
    logger.err('$e');
    exit(1);
  }
}
