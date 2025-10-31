import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/core/compatibility_checker.dart';
import 'package:pubmind/models/compatibility_input.dart';
import 'package:pubmind/utils/process_runner.dart';

Tool createCheckCompatibilityTool({
  required String projectDirectory,
  required ProcessRunner processRunner,
}) {
  return Tool.fromFunction<CheckCompatibilityInput, String>(
    name: 'check_package_compatibility',
    description:
        'Check if a package is compatible with the current project by performing a dry-run test before recommending it. ',
    inputJsonSchema: object({
      'package': string().min(1).meta(MetadataEntry(
            description: 'Package name to check',
          )),
      'version': string().meta(MetadataEntry(
        description: 'Optional specific version (e.g., "^1.0.0", "1.2.3")',
      )),
    }).optionals([
      'version',
    ]).toJsonSchema(),
    func: (CheckCompatibilityInput input) async {
      try {
        final checker = PackageCompatibilityChecker(
          projectDirectory: projectDirectory,
          processRunner: processRunner,
        );

        final result = await checker.checkCompatibilityOnly(
          packageName: input.package,
          version: input.version,
        );

        return result.formatReport();
      } catch (e) {
        return 'Error during compatibility check: $e';
      }
    },
    getInputFromJson: (json) => CheckCompatibilityInput.fromJson(json),
    handleToolError: (e) {
      return 'Check compatibility tool error : ${e.toString()}';
    },
  );
}
