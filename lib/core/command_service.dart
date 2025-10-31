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
  }) async {
    try {
      return switch (command) {
        'pub_get' => await _pubGet(),
        'pub_upgrade' => await _pubUpgrade(package),
        'pub_downgrade' => await _pubDowngrade(package),
        'pub_outdated' => await _pubOutdated(),
        'pub_remove' => await _pubRemove(package),
        'flutter_clean' => await _flutterClean(),
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
}
