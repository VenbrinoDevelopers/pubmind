import 'package:mason_logger/mason_logger.dart';

class ResponseFormatter {
  static String cleanMarkdown(String text) {
    var cleaned = text;

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^\*]+)\*\*|__([^_]+)__'),
      (match) => match.group(1) ?? match.group(2) ?? '',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*([^\*]+)\*|_([^_]+)_'),
      (match) => match.group(1) ?? match.group(2) ?? '',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'),
      (match) => '${match.group(1)} (${match.group(2)})',
    );

    return cleaned;
  }

  static void printFormatted(Logger logger, String response) {
    final cleaned = cleanMarkdown(response);
    final lines = cleaned.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        logger.info('');
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.)\s(.+)').firstMatch(line);
        if (match != null) {
          logger.info('${lightCyan.wrap(match.group(1)!)} ${match.group(2)}');
        } else {
          logger.info(line);
        }
      } else if (line.trim().startsWith('-') || line.trim().startsWith('•')) {
        final content = line.replaceFirst(RegExp(r'^[\s-•]+'), '');
        logger.info('  ${lightCyan.wrap('•')} $content');
      } else {
        logger.info(line);
      }
    }
  }
}
