class RunCommandInput {
  final String command;
  final String? package;
  final bool? isDev;
  final bool? apply;
  final String? buildTarget;
  final String? device;
  final String? testPath;
  final bool? deleteConflicting;
  final String? version;

  RunCommandInput({
    required this.command,
    this.package,
    this.isDev,
    this.apply,
    this.buildTarget,
    this.device,
    this.testPath,
    this.deleteConflicting,
    this.version,
  });

  factory RunCommandInput.fromJson(Map<String, dynamic> json) {
    return RunCommandInput(
      command: json['command'] as String,
      package: json['package'] as String?,
      isDev: json['isDev'] as bool?,
      apply: json['apply'] as bool?,
      buildTarget: json['buildTarget'] as String?,
      device: json['device'] as String?,
      testPath: json['testPath'] as String?,
      deleteConflicting: json['deleteConflicting'] as bool?,
      version: json['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      if (package != null) 'package': package,
      if (isDev != null) 'isDev': isDev,
      if (apply != null) 'apply': apply,
      if (buildTarget != null) 'buildTarget': buildTarget,
      if (device != null) 'device': device,
      if (testPath != null) 'testPath': testPath,
      if (deleteConflicting != null) 'deleteConflicting': deleteConflicting,
      if (version != null) 'version': version,
    };
  }
}
