import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pubmind/core/install_checker.dart';
import 'package:pubmind/models/compatibility_result.dart';
import 'package:pubmind/utils/process_runner.dart';
import 'package:yaml/yaml.dart';

class PackageCompatibilityChecker {
  final String projectDirectory;
  final ProcessRunner processRunner;

  PackageCompatibilityChecker({
    required this.projectDirectory,
    required this.processRunner,
  });

  Future<CompatibilityResult> checkCompatibilityOnly({
    required String packageName,
    String? version,
  }) async {
    try {
      final testResult = await processRunner.pubAddDryRun(
        packageName,
        version: version,
      );

      if (!testResult.success) {
        return CompatibilityResult(
          isCompatible: false,
          packageName: packageName,
          version: version,
          conflicts: _extractConflicts(testResult.stderr),
          warnings: _extractWarnings(testResult.stdout),
          errorMessage: _extractError(testResult.stderr),
        );
      }

      return CompatibilityResult(
        isCompatible: true,
        packageName: packageName,
        version: version,
        warnings: _extractWarnings(testResult.stdout),
      );
    } catch (e) {
      return CompatibilityResult(
        isCompatible: false,
        packageName: packageName,
        version: version,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<InstallationResult> install({
    required String packageName,
    String? version,
  }) async {
    final dryRunResult = await checkCompatibilityOnly(
      packageName: packageName,
      version: version,
    );

    if (!dryRunResult.isCompatible) {
      return InstallationResult(
        installSuccessful: false,
        packageName: packageName,
        version: version,
        warnings: dryRunResult.warnings,
        errorMessage: dryRunResult.errorMessage,
      );
    }

    final backupPath = await _backupPubspec();
    if (backupPath == null) {
      return InstallationResult(
        installSuccessful: false,
        packageName: packageName,
        errorMessage: 'Failed to create backup of pubspec.yaml',
      );
    }

    try {
      final installResult = await processRunner.pubAdd(
        packageName,
        version: version,
      );

      if (!installResult.success) {
        await _restorePubspec(backupPath);

        return InstallationResult(
          installSuccessful: false,
          packageName: packageName,
          version: version,
          warnings: _extractWarnings(installResult.stdout),
          errorMessage: _extractError(installResult.stderr),
        );
      }

      final verifyResult = await processRunner.pubGet();

      if (!verifyResult.success) {
        await _restorePubspec(backupPath);

        return InstallationResult(
          installSuccessful: false,
          packageName: packageName,
          version: version,
          errorMessage: 'Installation verification failed',
          warnings: _extractWarnings(verifyResult.stderr),
        );
      }

      final resolvedVersions = await _getResolvedVersions();
      await _deleteBackup(backupPath);

      return InstallationResult(
        installSuccessful: true,
        packageName: packageName,
        version: version,
        resolvedVersions: resolvedVersions,
        warnings: _extractWarnings(installResult.stdout),
      );
    } catch (e) {
      await _restorePubspec(backupPath);

      return InstallationResult(
        installSuccessful: false,
        packageName: packageName,
        version: version,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<String?> _backupPubspec() async {
    try {
      final pubspecPath = path.join(projectDirectory, 'pubspec.yaml');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath =
          path.join(projectDirectory, '.pubspec.backup.$timestamp.yaml');

      final pubspecFile = File(pubspecPath);
      await pubspecFile.copy(backupPath);

      return backupPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> _restorePubspec(String backupPath) async {
    try {
      final pubspecPath = path.join(projectDirectory, 'pubspec.yaml');
      final backupFile = File(backupPath);

      if (backupFile.existsSync()) {
        await backupFile.copy(pubspecPath);
        await _deleteBackup(backupPath);
      }
    } catch (e) {
      print('Warning: Failed to restore backup: $e');
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (backupFile.existsSync()) {
        await backupFile.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  Future<Map<String, String>> _getResolvedVersions() async {
    try {
      final lockPath = path.join(projectDirectory, 'pubspec.lock');
      final lockFile = File(lockPath);

      if (!lockFile.existsSync()) return {};

      final content = await lockFile.readAsString();
      final yaml = loadYaml(content) as Map;

      final versions = <String, String>{};
      if (yaml['packages'] != null) {
        final packages = yaml['packages'] as Map;
        for (final entry in packages.entries) {
          final pkgInfo = entry.value as Map;
          if (pkgInfo['version'] != null) {
            versions[entry.key.toString()] = pkgInfo['version'].toString();
          }
        }
      }

      return versions;
    } catch (e) {
      return {};
    }
  }

  List<String> _extractConflicts(String stderr) {
    final conflicts = <String>[];
    final lines = stderr.split('\n');

    for (final line in lines) {
      if (line.contains('conflict') ||
          line.contains('incompatible') ||
          line.contains('requires') && line.contains('but')) {
        conflicts.add(line.trim());
      }
    }

    return conflicts;
  }

  List<String> _extractWarnings(String output) {
    final warnings = <String>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.toLowerCase().contains('warning') ||
          line.contains('!') && !line.contains('✓')) {
        warnings.add(line.trim());
      }
    }

    return warnings;
  }

  String _extractError(String stderr) {
    if (stderr.isEmpty) return 'Unknown error occurred';

    final lines = stderr.split('\n');
    for (final line in lines) {
      if (line.contains('error:') || line.contains('Error:')) {
        return line.trim();
      }
    }

    return lines.first.trim();
  }
}
