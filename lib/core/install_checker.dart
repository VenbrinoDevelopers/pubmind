class InstallationResult {
  final bool installSuccessful;
  final String packageName;
  final String? version;
  final List<String> warnings;
  final String? errorMessage;
  final Map<String, String> resolvedVersions;

  InstallationResult({
    required this.installSuccessful,
    required this.packageName,
    this.version,
    this.warnings = const [],
    this.errorMessage,
    this.resolvedVersions = const {},
  });

  String formatReport() {
    final buffer = StringBuffer();

    buffer.writeln('📦 Package Installation Report for: $packageName');
    buffer.writeln('═' * 60);

    if (installSuccessful) {
      buffer.writeln('✅ Status: SUCCESSFULLY INSTALLED');
      buffer.writeln('📌 Version: ${version ?? "latest"}');

      if (resolvedVersions.isNotEmpty) {
        buffer.writeln('\n📊 Resolved Dependencies:');
        resolvedVersions.forEach((pkg, ver) {
          buffer.writeln('   • $pkg: $ver');
        });
      }

      if (warnings.isNotEmpty) {
        buffer.writeln('\n⚠️  Warnings:');
        for (final warning in warnings) {
          buffer.writeln('   • $warning');
        }
      }

      buffer.writeln('\n✨ Package has been added to your pubspec.yaml');
    } else {
      buffer.writeln('❌ Status: INSTALLATION FAILED');

      if (errorMessage != null) {
        buffer.writeln('\n🚫 Error: $errorMessage');
      }

      if (warnings.isNotEmpty) {
        buffer.writeln('\n⚠️  Issues:');
        for (final warning in warnings) {
          buffer.writeln('   • $warning');
        }
      }

      buffer.writeln('\n💡 Your project has been restored to its previous state');
    }

    return buffer.toString();
  }
}