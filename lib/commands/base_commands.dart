import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:pubmind/utils/commands_helper.dart';

abstract class BaseCommand extends Command<int> {
  BaseCommand(this.logger) {
    argParser
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'The project directory to work in.',
        defaultsTo: '.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Enable verbose logging.',
      )
      ..addOption(
        'api-key',
        help: 'OpenAI API key (or use OPENAI_API_KEY env var).',
      );
  }

  final Logger logger;

  String get projectDirectory {
    final dir = argResults?['directory'] as String? ?? '.';
    return path.absolute(dir);
  }

  bool get verbose => argResults?['verbose'] as bool? ?? false;

  String? _cachedApiKey;

  String? get apiKey {
    if (_cachedApiKey != null) return _cachedApiKey;

    final fromArgs = argResults?['api-key'] as String?;
    if (fromArgs != null && fromArgs.isNotEmpty) {
      _cachedApiKey = fromArgs;
      return _cachedApiKey;
    }

    final fromEnv = Platform.environment['OPENAI_API_KEY'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      _cachedApiKey = fromEnv;
      return _cachedApiKey;
    }

    final fromConfig = CommandsHelper.readApiKeyFromConfig();
    if (fromConfig != null) {
      _cachedApiKey = fromConfig;
      return _cachedApiKey;
    }

    return null;
  }

  bool get isFlutterProject {
    final pubspecFile = File(path.join(projectDirectory, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('flutter:') || content.contains('sdk: flutter');
  }

  Future<bool> validateProjectDirectory() async {
    final dir = Directory(projectDirectory);

    if (!await dir.exists()) {
      logger.err('Directory not found: $projectDirectory');
      return false;
    }

    final pubspecFile = File(path.join(projectDirectory, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      logger.err('No pubspec.yaml found in: $projectDirectory');
      logger.info('Make sure you are in a Dart or Flutter project directory.');
      return false;
    }

    return true;
  }

  Future<bool> validateApiKey() async {
    if (apiKey != null && apiKey!.isNotEmpty) {
      return true;
    }

    logger.info('');
    logger.info('${lightCyan.wrap('OpenAI API key required')}');
    logger.info('');
    logger.info(
        'Get your API key from: ${lightCyan.wrap('https://platform.openai.com/api-keys')}');
    logger.info('');

    try {
      final key = Input(
        prompt: 'Enter your OpenAI API key',
        validator: (value) {
          if (value.isEmpty) return false;
          if (!value.startsWith('sk-')) return false;
          return true;
        },
      ).interact();

      _cachedApiKey = key;

      final shouldSave = Confirm(
        prompt: 'Save API key to ~/.pubmind/config.json for future use?',
        defaultValue: true,
      ).interact();

      if (shouldSave) {
        final saved = CommandsHelper.saveApiKeyToConfig(key);
        if (saved) {
          logger.success('API key saved successfully!');
        } else {
          logger.warn('Failed to save API key to config file');
        }
      }

      logger.info('');
      return true;
    } catch (e) {
      logger.err('Failed to get API key: $e');
      return false;
    }
  }

  @override
  Future<int> run() async {
    try {
      if (!await validateProjectDirectory()) {
        return ExitCode.usage.code;
      }

      if (!await validateApiKey()) {
        return ExitCode.config.code;
      }

      return await execute();
    } catch (e, stackTrace) {
      logger.err('Command failed: $e');
      if (verbose) {
        logger.detail('Stack trace: $stackTrace');
      }
      return ExitCode.software.code;
    }
  }

  Future<int> execute();
}
