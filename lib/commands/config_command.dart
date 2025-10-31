import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

class ConfigCommand extends Command<int> {
  ConfigCommand(this.logger) {
    addSubcommand(ConfigSetCommand(logger));
    addSubcommand(ConfigShowCommand(logger));
    addSubcommand(ConfigDeleteCommand(logger));
  }

  final Logger logger;

  @override
  String get name => 'config';

  @override
  String get description => 'Manage PubMind configuration';

  @override
  String get invocation => 'pubmind config <subcommand>';

  @override
  Future<int> run() async {
    logger.info('Available subcommands:');
    logger.info('  set     - Set configuration values');
    logger.info('  show    - Show current configuration');
    logger.info('  delete  - Delete configuration');
    logger.info('');
    logger.info('Usage: pubmind config <subcommand>');
    return ExitCode.usage.code;
  }
}

class ConfigSetCommand extends Command<int> {
  ConfigSetCommand(this.logger) {
    argParser.addOption(
      'api-key',
      help: 'OpenAI API key to save',
    );
  }

  final Logger logger;

  @override
  String get name => 'set';

  @override
  String get description => 'Set configuration values';

  @override
  String get invocation => 'pubmind config set --api-key <key>';

  String get _configPath {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return path.join(home!, '.pubmind', 'config.json');
  }

  @override
  Future<int> run() async {
    final apiKey = argResults?['api-key'] as String?;

    if (apiKey == null || apiKey.isEmpty) {
      logger.err('Please provide an API key');
      logger.info('');
      logger.info('Usage: pubmind config set --api-key sk-...');
      return ExitCode.usage.code;
    }

    if (!apiKey.startsWith('sk-')) {
      logger.err('Invalid API key format. Key should start with sk-');
      return ExitCode.usage.code;
    }

    try {
      final configDir = Directory(path.dirname(_configPath));
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }

      final config = {'openai_api_key': apiKey};
      File(_configPath).writeAsStringSync(
        jsonEncode(config),
        mode: FileMode.write,
      );

      logger.success('API key saved successfully!');
      logger.info('');
      logger.info('Config saved to: ${darkGray.wrap(_configPath)}');
      return ExitCode.success.code;
    } catch (e) {
      logger.err('Failed to save configuration: $e');
      return ExitCode.software.code;
    }
  }
}

class ConfigShowCommand extends Command<int> {
  ConfigShowCommand(this.logger);

  final Logger logger;

  @override
  String get name => 'show';

  @override
  String get description => 'Show current configuration';

  @override
  String get invocation => 'pubmind config show';

  String get _configPath {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return path.join(home!, '.pubmind', 'config.json');
  }

  @override
  Future<int> run() async {
    final configFile = File(_configPath);

    if (!configFile.existsSync()) {
      logger.info('No configuration file found');
      logger.info('');
      logger.info(
          'Run ${lightCyan.wrap('pubmind config set --api-key sk-...')} to create one');
      return ExitCode.success.code;
    }

    try {
      final content = configFile.readAsStringSync();
      final config = jsonDecode(content) as Map<String, dynamic>;

      logger.info('📄 ${lightCyan.wrap('Configuration:')}');
      logger.info('');
      logger.info('Config file: ${darkGray.wrap(_configPath)}');
      logger.info('');

      if (config.containsKey('openai_api_key')) {
        final key = config['openai_api_key'] as String;
        final maskedKey =
            '${key.substring(0, 7)}...${key.substring(key.length - 4)}';
        logger.info('OpenAI API Key: ${lightGreen.wrap(maskedKey)}');
      } else {
        logger.info('OpenAI API Key: ${darkGray.wrap('Not set')}');
      }

      return ExitCode.success.code;
    } catch (e) {
      logger.err('Failed to read configuration: $e');
      return ExitCode.software.code;
    }
  }
}

class ConfigDeleteCommand extends Command<int> {
  ConfigDeleteCommand(this.logger);

  final Logger logger;

  @override
  String get name => 'delete';

  @override
  String get description => 'Delete configuration file';

  @override
  String get invocation => 'pubmind config delete';

  String get _configPath {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return path.join(home!, '.pubmind', 'config.json');
  }

  @override
  Future<int> run() async {
    final configFile = File(_configPath);

    if (!configFile.existsSync()) {
      logger.info('No configuration file to delete');
      return ExitCode.success.code;
    }

    try {
      configFile.deleteSync();
      logger.success('Configuration deleted successfully!');
      logger.info('');
      logger.info('Deleted: ${darkGray.wrap(_configPath)}');
      return ExitCode.success.code;
    } catch (e) {
      logger.err('Failed to delete configuration: $e');
      return ExitCode.software.code;
    }
  }
}
