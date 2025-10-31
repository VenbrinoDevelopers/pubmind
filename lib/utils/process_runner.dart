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

  Future<RunnerProcessResult> pubGet() async {
    if (verbose) print('🔄 Running $executable pub get...');
    return _runCommand(executable, ['pub', 'get']);
  }

  Future<RunnerProcessResult> pubAdd(String package, {String? version}) async {
    final args = ['pub', 'add', version != null ? '$package:$version' : package];
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
