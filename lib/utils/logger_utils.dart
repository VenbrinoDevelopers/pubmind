import 'package:mason_logger/mason_logger.dart';

class LoggerUtils {
  static void printBanner(Logger logger) {
    logger.info('''
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🤖 ${lightCyan.wrap('PubMind')} - AI Package Manager                    ║
║                                                           ║
║   Intelligent package recommendations & management        ║
║   for Dart and Flutter projects                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
''');
  }

  static void printWelcomeBanner(
      Logger logger, String model, String projectDirectory, bool withTools) {
    logger.info('');
    logger.info('╔════════════════════════════════════════════════════════╗');
    logger.info(
        '║  🤖 ${lightCyan.wrap('PubMind AI Chat')} - Interactive Package Assistant  ║');
    logger.info('╚════════════════════════════════════════════════════════╝');
    logger.info('');
    logger.info('${darkGray.wrap('Model:')} ${lightGreen.wrap(model)}');
    logger.info(
        '${darkGray.wrap('Project:')} ${lightGreen.wrap(projectDirectory)}');
    logger.info(
        '${darkGray.wrap('Tools:')} ${withTools ? lightGreen.wrap('Enabled') : darkGray.wrap('Disabled')}');
    logger.info('');
  }

  static void printCommands(Logger logger) {
    logger.info('${lightYellow.wrap('Available commands:')}');
    logger.info('  ${lightCyan.wrap('/help')}    - Show this help message');
    logger.info('  ${lightCyan.wrap('/clear')}   - Clear conversation history');
    logger.info('  ${lightCyan.wrap('/history')} - Show conversation history');
    logger.info('  ${lightCyan.wrap('/exit')}    - Exit the chat');
    logger.info('');
    logger.info(
        '${darkGray.wrap('Type your message and press Enter. Enter /exit to exit.')}');
    logger.info('');
  }
}
