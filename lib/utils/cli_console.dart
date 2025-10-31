import 'package:mason_logger/mason_logger.dart';

class CliConsoleLogger {
  static logAgentResponse(String response) {
    final logger = Logger();
    logger.info('');
    logger.info('${lightGreen.wrap('AI')} > $response');
    logger.info('');
  }
}
