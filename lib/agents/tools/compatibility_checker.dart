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
        'Verify if a package can be safely added to the project without conflicts. '
        'Performs a dry-run test that checks SDK constraints, dependency conflicts, and version compatibility. '
        'Use this ONCE before installing a package. Returns detailed compatibility report. '
        'IMPORTANT: Do not call this repeatedly - check once, then proceed with install_package or try an alternative.',
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
