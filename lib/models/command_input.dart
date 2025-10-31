class RunCommandInput {
  final String command;
  final String? package;

  RunCommandInput({
    required this.command,
    this.package,
  });

  RunCommandInput.fromJson(Map<String, dynamic> json)
      : command = json['command'] as String,
        package = json['package'] as String?;
}