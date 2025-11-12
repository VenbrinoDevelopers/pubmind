import 'package:pubmind/utils/process_runner.dart';

class CommandResult {
  final bool success;
  final String message;

  const CommandResult({
    required this.success,
    required this.message,
  });
}

class CommandService {
  final ProcessRunner processRunner;

  CommandService({required this.processRunner});

  Future<CommandResult> executeCommand({
    required String command,
    String? package,
    bool? isDev,
    bool? apply,
    String? buildTarget,
    String? device,
    String? testPath,
    String? version,
    bool? deleteConflicting,
  }) async {
    try {
      return switch (command) {
        // Existing commands
        'pub_get' => await _pubGet(),
        'pub_upgrade' => await _pubUpgrade(package),
        'pub_downgrade' => await _pubDowngrade(package),
        'pub_outdated' => await _pubOutdated(),
        'pub_remove' => await _pubRemove(package),
        'flutter_clean' => await _flutterClean(),

        // New dependency management commands
        'pub_add' => await _pubAdd(package, isDev ?? false, version),
        'pub_deps' => await _pubDeps(),
        'pub_cache_repair' => await _pubCacheRepair(),

        // Code analysis & quality commands
        'dart_analyze' => await _dartAnalyze(),
        'dart_fix' => await _dartFix(apply ?? false),
        'dart_format' => await _dartFormat(),

        // Testing commands
        'flutter_test' => await _flutterTest(testPath),
        'flutter_test_coverage' => await _flutterTestCoverage(),

        // Flutter-specific commands
        'flutter_doctor' => await _flutterDoctor(),
        'flutter_upgrade' => await _flutterUpgrade(),
        'flutter_pub_cache_clean' => await _flutterPubCacheClean(),
        'flutter_build' => await _flutterBuild(buildTarget),
        'flutter_run' => await _flutterRun(device),

        // Build runner commands
        'build_runner_build' =>
          await _buildRunnerBuild(deleteConflicting ?? false),
        'build_runner_watch' => await _buildRunnerWatch(),
        'build_runner_clean' => await _buildRunnerClean(),
        _ => CommandResult(
            success: false,
            message: '❌ Unknown command: $command',
          ),
      };
    } catch (e) {
      return CommandResult(
        success: false,
        message: '❌ Command execution error: $e',
      );
    }
  }

  // ========== EXISTING COMMANDS ==========

  Future<CommandResult> _pubGet() async {
    final buffer = StringBuffer();
    buffer.writeln('📥 Running pub get...');
    buffer.writeln('');

    final result = await processRunner.pubGet();

    if (result.success) {
      buffer.writeln('✅ Dependencies fetched successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ pub get failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubUpgrade(String? package) async {
    final buffer = StringBuffer();

    if (package != null) {
      buffer.writeln('⬆️  Upgrading $package...');
    } else {
      buffer.writeln('⬆️  Upgrading all packages...');
    }
    buffer.writeln('');

    final result = await processRunner.pubUpgrade(package);

    if (result.success) {
      buffer.writeln('✅ ${package ?? "All packages"} upgraded successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Upgrade failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubDowngrade(String? package) async {
    final buffer = StringBuffer();

    if (package != null) {
      buffer.writeln('⬇️  Downgrading $package...');
    } else {
      buffer.writeln('⬇️  Downgrading all packages...');
    }
    buffer.writeln('');

    final result = await processRunner.pubDowngrade(package);

    if (result.success) {
      buffer.writeln('✅ ${package ?? "All packages"} downgraded successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Downgrade failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubOutdated() async {
    final buffer = StringBuffer();
    buffer.writeln('🔍 Checking for outdated packages...');
    buffer.writeln('');

    final result = await processRunner.pubOutdated(json: false);

    if (result.success) {
      buffer.writeln('📊 Outdated packages report:');
      buffer.writeln('');
      buffer.writeln(result.stdout);
    } else {
      buffer.writeln('❌ Failed to check outdated packages');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubRemove(String? package) async {
    if (package == null) {
      return const CommandResult(
        success: false,
        message: '❌ Package name is required for pub_remove command',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🗑️  Removing $package...');
    buffer.writeln('');

    final result = await processRunner.pubRemove(package);

    if (result.success) {
      buffer.writeln('✅ $package removed successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to remove $package');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterClean() async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message:
            '❌ This is not a Flutter project. flutter clean can only be run in Flutter projects.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🧹 Running flutter clean...');
    buffer.writeln('');

    final result = await processRunner.flutterClean();

    if (result.success) {
      buffer.writeln('✅ Build files cleaned successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ flutter clean failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  // ========== NEW DEPENDENCY MANAGEMENT COMMANDS ==========

  Future<CommandResult> _pubAdd(
      String? package, bool isDev, String? version) async {
    if (package == null) {
      return const CommandResult(
        success: false,
        message: '❌ Package name is required for pub_add command',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('📦 Adding $package${isDev ? " (dev dependency)" : ""}...');
    buffer.writeln('');

    final result =
        await processRunner.pubAdd(package, dev: isDev, version: version);

    if (result.success) {
      buffer.writeln('✅ $package added successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to add $package');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubDeps() async {
    final buffer = StringBuffer();
    buffer.writeln('📊 Analyzing dependency tree...');
    buffer.writeln('');

    final result = await processRunner.pubDeps();

    if (result.success) {
      buffer.writeln('Dependency tree:');
      buffer.writeln('');
      buffer.writeln(result.stdout);
    } else {
      buffer.writeln('❌ Failed to analyze dependencies');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _pubCacheRepair() async {
    final buffer = StringBuffer();
    buffer.writeln('🔧 Repairing pub cache...');
    buffer.writeln('');

    final result = await processRunner.pubCacheRepair();

    if (result.success) {
      buffer.writeln('✅ Pub cache repaired successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Output:');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to repair pub cache');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  // ========== CODE ANALYSIS & QUALITY COMMANDS ==========

  Future<CommandResult> _dartAnalyze() async {
    final buffer = StringBuffer();
    buffer.writeln('🔍 Analyzing code...');
    buffer.writeln('');

    final result = await processRunner.dartAnalyze();

    if (result.success) {
      buffer.writeln('✅ Analysis complete');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      } else {
        buffer.writeln('No issues found!');
      }
    } else {
      buffer.writeln('⚠️  Analysis found issues:');
      buffer.writeln('');
      buffer.writeln(result.stdout);
      if (result.stderr.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Errors:');
        buffer.writeln(result.stderr);
      }
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _dartFix(bool apply) async {
    final buffer = StringBuffer();
    buffer.writeln(
        apply ? '🔧 Applying fixes...' : '🔍 Checking for fixes (dry run)...');
    buffer.writeln('');

    final result = await processRunner.dartFix(apply: apply);

    if (result.success) {
      buffer.writeln(
          apply ? '✅ Fixes applied successfully' : '✅ Fix analysis complete');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ dart fix failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _dartFormat() async {
    final buffer = StringBuffer();
    buffer.writeln('✨ Formatting code...');
    buffer.writeln('');

    final result = await processRunner.dartFormat();

    if (result.success) {
      buffer.writeln('✅ Code formatted successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ dart format failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  // ========== TESTING COMMANDS ==========

  Future<CommandResult> _flutterTest(String? testPath) async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(testPath != null
        ? '🧪 Running tests in $testPath...'
        : '🧪 Running all tests...');
    buffer.writeln('');

    final result = await processRunner.flutterTest(testPath: testPath);

    if (result.success) {
      buffer.writeln('✅ Tests passed');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Tests failed');
      buffer.writeln('');
      buffer.writeln(result.stdout);
      if (result.stderr.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Errors:');
        buffer.writeln(result.stderr);
      }
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterTestCoverage() async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 Running tests with coverage...');
    buffer.writeln('');

    final result = await processRunner.flutterTestCoverage();

    if (result.success) {
      buffer.writeln('✅ Coverage report generated');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
      buffer.writeln('');
      buffer.writeln('Coverage report saved to coverage/lcov.info');
    } else {
      buffer.writeln('❌ Coverage generation failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  // ========== FLUTTER-SPECIFIC COMMANDS ==========

  Future<CommandResult> _flutterDoctor() async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🏥 Running Flutter doctor...');
    buffer.writeln('');

    final result = await processRunner.flutterDoctor();

    if (result.success) {
      buffer.writeln('Flutter environment status:');
      buffer.writeln('');
      buffer.writeln(result.stdout);
    } else {
      buffer.writeln('⚠️  Flutter doctor found issues:');
      buffer.writeln('');
      buffer.writeln(result.stdout);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterUpgrade() async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('⬆️  Upgrading Flutter...');
    buffer.writeln('');

    final result = await processRunner.flutterUpgrade();

    if (result.success) {
      buffer.writeln('✅ Flutter upgraded successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Flutter upgrade failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterPubCacheClean() async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🧹 Cleaning Flutter pub cache...');
    buffer.writeln('');

    final result = await processRunner.flutterPubCacheClean();

    if (result.success) {
      buffer.writeln('✅ Pub cache cleaned successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to clean pub cache');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterBuild(String? buildTarget) async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    if (buildTarget == null) {
      return const CommandResult(
        success: false,
        message: '❌ Build target is required (e.g., apk, ios, web, appbundle)',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🔨 Building Flutter app for $buildTarget...');
    buffer.writeln('');

    final result = await processRunner.flutterBuild(buildTarget);

    if (result.success) {
      buffer.writeln('✅ Build completed successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Build failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _flutterRun(String? device) async {
    if (!processRunner.isFlutterProject) {
      return const CommandResult(
        success: false,
        message: '❌ This is not a Flutter project.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(device != null
        ? '🚀 Running Flutter app on $device...'
        : '🚀 Running Flutter app...');
    buffer.writeln('');

    final result = await processRunner.flutterRun(device: device);

    if (result.success) {
      buffer.writeln('✅ App started successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to run app');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  // ========== BUILD RUNNER COMMANDS ==========

  Future<CommandResult> _buildRunnerBuild(bool deleteConflicting) async {
    final buffer = StringBuffer();
    buffer.writeln(
        '⚙️  Running build_runner build${deleteConflicting ? " (deleting conflicting outputs)" : ""}...');
    buffer.writeln('');

    final result = await processRunner.buildRunnerBuild(
      deleteConflicting: deleteConflicting,
    );

    if (result.success) {
      buffer.writeln('✅ Code generation completed successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Code generation failed');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _buildRunnerWatch() async {
    final buffer = StringBuffer();
    buffer.writeln('👁️  Starting build_runner in watch mode...');
    buffer.writeln('');

    final result = await processRunner.buildRunnerWatch();

    if (result.success) {
      buffer.writeln('✅ Build runner watch started');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to start build runner watch');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }

  Future<CommandResult> _buildRunnerClean() async {
    final buffer = StringBuffer();
    buffer.writeln('🧹 Cleaning build_runner cache...');
    buffer.writeln('');

    final result = await processRunner.buildRunnerClean();

    if (result.success) {
      buffer.writeln('✅ Build runner cache cleaned successfully');
      if (result.stdout.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(result.stdout);
      }
    } else {
      buffer.writeln('❌ Failed to clean build runner cache');
      buffer.writeln('');
      buffer.writeln('Error:');
      buffer.writeln(result.stderr);
    }

    return CommandResult(
      success: result.success,
      message: buffer.toString(),
    );
  }
}
