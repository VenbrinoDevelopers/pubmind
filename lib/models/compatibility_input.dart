class CheckCompatibilityInput {
  const CheckCompatibilityInput({
    required this.package,
    this.version,
  });

  final String package;
  final String? version;

  CheckCompatibilityInput.fromJson(Map<String, dynamic> json)
      : this(
          package: json['package'] as String,
          version: json['version'] as String?,
        );
}