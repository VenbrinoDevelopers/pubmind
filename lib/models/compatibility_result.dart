class CompatibilityResult {
  final bool isCompatible;
  final String packageName;
  final String? version;
  final List<String> conflicts;
  final List<String> warnings;
  final String? errorMessage;

  CompatibilityResult({
    required this.isCompatible,
    required this.packageName,
    this.version,
    this.conflicts = const [],
    this.warnings = const [],
    this.errorMessage,
  });

  String formatReport() {
    final buffer = StringBuffer();

    buffer.writeln('📦 Package Compatibility Report for: $packageName');
    buffer.writeln('═' * 60);

    if (isCompatible) {
      buffer.writeln('✅ Status: COMPATIBLE');
      buffer.writeln('📌 Version: ${version ?? "latest"}');

      if (warnings.isNotEmpty) {
        buffer.writeln('\n⚠️  Warnings:');
        for (final warning in warnings) {
          buffer.writeln('   • $warning');
        }
      }

      buffer.writeln('\n✨ This package can be safely added to your project');
    } else {
      buffer.writeln('❌ Status: INCOMPATIBLE');

      if (errorMessage != null) {
        buffer.writeln('\n🚫 Error: $errorMessage');
      }

      if (conflicts.isNotEmpty) {
        buffer.writeln('\n⚠️  Conflicts Detected:');
        for (final conflict in conflicts) {
          buffer.writeln('   • $conflict');
        }
      }

      if (warnings.isNotEmpty) {
        buffer.writeln('\n⚠️  Additional Issues:');
        for (final warning in warnings) {
          buffer.writeln('   • $warning');
        }
      }

      buffer.writeln('\n💡 Suggestions:');
      buffer.writeln('   • Try a different version of the package');
      buffer.writeln('   • Check if any existing dependencies need updating');
      buffer.writeln('   • Review the package\'s compatibility requirements');
    }

    return buffer.toString();
  }
}
