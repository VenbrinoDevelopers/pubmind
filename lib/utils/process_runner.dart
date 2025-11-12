import 'dart:io';
import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as path;
import 'package:pubmind/models/process_result.dart';

class ProcessRunner {
  final String workingDirectory;
  final bool verbose;

  ProcessRunner({
    required this.workingDirectory,
    this.verbose = false,
  });

  bool get isFlutterProject {
    final pubspecFile = File(path.join(workingDirectory, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;

    final content = pubspecFile.readAsStringSync();
    return content.contains('flutter:') || content.contains('sdk: flutter');
  }

  String get executable => isFlutterProject ? 'flutter' : 'dart';

  // ========== EXISTING METHODS ==========

  Future<RunnerProcessResult> pubGet() async {
    if (verbose) print('🔄 Running $executable pub get...');
    return _runCommand(executable, ['pub', 'get']);
  }

  Future<RunnerProcessResult> pubAdd(String package,
      {String? version, bool dev = false}) async {
    final args = [
      'pub',
      'add',
      version != null ? '$package:$version' : package
    ];
    if (dev) args.add('--dev');
    if (verbose) print('📦 Running $executable ${args.join(' ')}...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> pubAddDryRun(String package,
      {String? version}) async {
    final args = [
      'pub',
      'add',
      version != null ? '$package:$version' : package,
      '--dry-run',
    ];
    if (verbose) print('📦 Running $executable ${args.join(' ')}...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> pubRemove(String package) async {
    if (verbose) print('🗑️  Removing package $package...');
    return _runCommand(executable, ['pub', 'remove', package]);
  }

  Future<RunnerProcessResult> pubUpgrade([String? package]) async {
    final args = ['pub', 'upgrade'];
    if (package != null) args.add(package);
    if (verbose) print('⬆️  Running $executable ${args.join(' ')}...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> pubOutdated({bool json = false}) async {
    final args = ['pub', 'outdated'];
    if (json) args.add('--json');
    if (verbose) print('🔍 Checking outdated packages...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> pubDowngrade([String? package]) async {
    final args = ['pub', 'downgrade'];
    if (package != null) args.add(package);
    if (verbose) print('⬇️  Running $executable ${args.join(' ')}...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> flutterClean() async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }
    if (verbose) print('🧹 Running flutter clean...');
    return _runCommand('flutter', ['clean']);
  }

  Future<RunnerProcessResult> runPubCommand(List<String> args) async {
    if (verbose) print('▶️  Running $executable pub ${args.join(' ')}...');
    return _runCommand(executable, ['pub', ...args]);
  }

  // ========== NEW DEPENDENCY MANAGEMENT METHODS ==========

  Future<RunnerProcessResult> pubDeps() async {
    if (verbose) print('📊 Running $executable pub deps...');
    return _runCommand(executable, ['pub', 'deps']);
  }

  Future<RunnerProcessResult> pubCacheRepair() async {
    if (verbose) print('🔧 Running $executable pub cache repair...');
    return _runCommand(executable, ['pub', 'cache', 'repair']);
  }

  // ========== CODE ANALYSIS & QUALITY METHODS ==========

  Future<RunnerProcessResult> dartAnalyze() async {
    if (verbose) print('🔍 Running dart analyze...');
    return _runCommand('dart', ['analyze']);
  }

  Future<RunnerProcessResult> dartFix({bool apply = false}) async {
    final args = ['fix'];
    if (apply) {
      args.add('--apply');
    } else {
      args.add('--dry-run');
    }
    if (verbose) print('🔧 Running dart ${args.join(' ')}...');
    return _runCommand('dart', args);
  }

  Future<RunnerProcessResult> dartFormat() async {
    if (verbose) print('✨ Running dart format...');
    return _runCommand('dart', ['format', '.']);
  }

  // ========== TESTING METHODS ==========

  Future<RunnerProcessResult> flutterTest({String? testPath}) async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }

    final args = ['test'];
    if (testPath != null) args.add(testPath);

    if (verbose) print('🧪 Running flutter ${args.join(' ')}...');
    return _runCommand('flutter', args);
  }

  Future<RunnerProcessResult> flutterTestCoverage() async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }

    if (verbose) print('📊 Running flutter test with coverage...');
    return _runCommand('flutter', ['test', '--coverage']);
  }

  // ========== FLUTTER-SPECIFIC METHODS ==========

  Future<RunnerProcessResult> flutterDoctor() async {
    if (verbose) print('🏥 Running flutter doctor...');
    return _runCommand('flutter', ['doctor', '-v']);
  }

  Future<RunnerProcessResult> flutterUpgrade() async {
    if (verbose) print('⬆️  Running flutter upgrade...');
    return _runCommand('flutter', ['upgrade']);
  }

  Future<RunnerProcessResult> flutterPubCacheClean() async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }

    if (verbose) print('🧹 Running flutter pub cache clean...');
    return _runCommand('flutter', ['pub', 'cache', 'clean']);
  }

  Future<RunnerProcessResult> flutterBuild(String target) async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }

    if (verbose) print('🔨 Running flutter build $target...');
    return _runCommand('flutter', ['build', target]);
  }

  Future<RunnerProcessResult> flutterRun({String? device}) async {
    if (!isFlutterProject) {
      return RunnerProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Not a Flutter project',
      );
    }

    final args = ['run'];
    if (device != null) {
      args.addAll(['-d', device]);
    }

    if (verbose) print('🚀 Running flutter ${args.join(' ')}...');
    return _runCommand('flutter', args);
  }

  // ========== BUILD RUNNER METHODS ==========

  Future<RunnerProcessResult> buildRunnerBuild(
      {bool deleteConflicting = false}) async {
    final args = ['run', 'build_runner', 'build'];
    if (deleteConflicting) {
      args.add('--delete-conflicting-outputs');
    }

    if (verbose) print('⚙️  Running $executable ${args.join(' ')}...');
    return _runCommand(executable, args);
  }

  Future<RunnerProcessResult> buildRunnerWatch() async {
    if (verbose) print('👁️  Running $executable run build_runner watch...');
    return _runCommand(executable, ['run', 'build_runner', 'watch']);
  }

  Future<RunnerProcessResult> buildRunnerClean() async {
    if (verbose) print('🧹 Running $executable run build_runner clean...');
    return _runCommand(executable, ['run', 'build_runner', 'clean']);
  }

  // ========== STATIC UTILITY METHODS ==========

  static Future<bool> isDartAvailable() async {
    try {
      final result = await Process.run('dart', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isFlutterAvailable() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static String? getDartSdkPath() {
    try {
      return sdkPath;
    } catch (e) {
      return null;
    }
  }

  // ========== INTERNAL METHODS ==========

  /// Internal method to run commands
  Future<RunnerProcessResult> _runCommand(
    String command,
    List<String> arguments,
  ) async {
    try {
      final result = await Process.run(
        command,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

      if (verbose) {
        if (result.stdout.toString().isNotEmpty) {
          print(result.stdout);
        }
        if (result.stderr.toString().isNotEmpty) {
          print(result.stderr);
        }
      }

      return RunnerProcessResult(
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );
    } catch (e) {
      return RunnerProcessResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  Future<RunnerProcessResult> runCommandStreaming(
    String command,
    List<String> arguments,
  ) async {
    try {
      final process = await Process.start(
        command,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      process.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        stdoutBuffer.write(output);
        if (verbose) stdout.write(output);
      });

      process.stderr.listen((data) {
        final output = String.fromCharCodes(data);
        stderrBuffer.write(output);
        if (verbose) stderr.write(output);
      });

      final exitCode = await process.exitCode;

      return RunnerProcessResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } catch (e) {
      return RunnerProcessResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }
}
