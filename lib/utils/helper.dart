String cleanMarkdown(String input) {
  return input
      // Remove markdown headers (###, ##, #)
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      // Remove bold/italic markers
      .replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '')
      // Remove inline code/backticks
      .replaceAll('`', '')
      // Remove list markers (-, *, +)
      .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
      // Remove extra newlines
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
