import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/core/compatibility_checker.dart';
import 'package:pubmind/models/compatibility_input.dart';
import 'package:pubmind/utils/process_runner.dart';

Tool createInstallPackageTool({
  required String projectDirectory,
  required ProcessRunner processRunner,
}) {
  return Tool.fromFunction<CheckCompatibilityInput, String>(
      name: 'install_package',
      description:
          'Install a package to the project. This will modify pubspec.yaml and run pub get. '
          'Only use this tool if the user has confrim that you can install'
          'call check_package_compatibility tool before using this tool'
          'The installation includes automatic backup and can be restored if it fails.',
      inputJsonSchema: object({
        'package': string().min(1).meta(
              MetadataEntry(description: 'Package name to install'),
            ),
        'version': string().meta(
          MetadataEntry(
            description:
                'version constraint (e.g., "^1.0.0", "1.2.3"). If not provided, uses latest compatible version.',
          ),
        ),
      }).toJsonSchema(),
      func: (input) async {
        try {
          final checker = PackageCompatibilityChecker(
            projectDirectory: projectDirectory,
            processRunner: processRunner,
          );

          final result = await checker.install(
            packageName: input.package,
            version: input.version,
          );

          return result.formatReport();
        } catch (e) {
          return 'Error during installation: $e';
        }
      },
      getInputFromJson: (json) => CheckCompatibilityInput.fromJson(json),
      handleToolError: (e) {
        return 'Install tool error : ${e.toString()}';
      });
}
