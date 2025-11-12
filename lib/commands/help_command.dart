import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class HelpCommand extends Command<int> {
  HelpCommand(this.logger) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging.',
    );
  }

  final Logger logger;

  @override
  String get description => 'Display help information for CLI commands.';

  @override
  String get name => 'help';

  @override
  Future<int> run() async {
    logger.info('Available commands:');
    logger.info('  help - Display help information for CLI commands.');
    logger.info('  command1 - Description for command1.');
    logger.info('  command2 - Description for command2.');
    logger.info('  command3 - Description for command3.');
    // Add other commands here
    return 0;
  }
}
