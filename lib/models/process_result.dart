class RunnerProcessResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool success;

  RunnerProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  }) : success = exitCode == 0;

  @override
  String toString() => 'ProcessResult(exitCode: $exitCode, success: $success)';
}
