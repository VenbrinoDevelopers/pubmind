import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/core/command_service.dart';
import 'package:pubmind/core/data/enum.dart';
import 'package:pubmind/models/command_input.dart';

Tool createRunCommandTool({
  required CommandService commandService,
}) {
  return Tool.fromFunction<RunCommandInput, String>(
    name: 'run_command',
    description:
        'Execute common Dart/Flutter pub commands for project maintenance and development. '
        'Supports dependency management, code quality, testing, building, and more. '
        'Use for installing packages, running tests, analyzing code, building apps, and troubleshooting.',
    inputJsonSchema: object({
      'command': string().enumerated(
        PubCommand.values,
        nameTransformer: (name) {
          return name.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (match) => '_${match.group(0)!.toLowerCase()}',
          );
        },
      ).meta(MetadataEntry(
        description: 'Command to run. Available options:\n\n'
            '📦 DEPENDENCY MANAGEMENT:\n'
            '- pub_add: Install/add a new package to project\n'
            '- pub_get: Fetch all dependencies from pubspec.yaml\n'
            '- pub_upgrade: Upgrade all or specific package to latest\n'
            '- pub_downgrade: Downgrade all or specific package\n'
            '- pub_remove: Uninstall/remove a package from project\n'
            '- pub_outdated: Check which packages have updates available\n'
            '- pub_deps: Show dependency tree\n'
            '- pub_cache_repair: Repair corrupted pub cache\n\n'
            '🔍 CODE ANALYSIS & QUALITY:\n'
            '- dart_analyze: Run static code analysis\n'
            '- dart_fix: Apply automated code fixes (use apply param)\n'
            '- dart_format: Format all Dart code\n\n'
            '🧪 TESTING:\n'
            '- flutter_test: Run tests (all or specific path)\n'
            '- flutter_test_coverage: Generate test coverage report\n\n'
            '🔵 FLUTTER COMMANDS:\n'
            '- flutter_doctor: Check Flutter environment setup\n'
            '- flutter_upgrade: Upgrade Flutter SDK\n'
            '- flutter_clean: Clean build files and cache\n'
            '- flutter_pub_cache_clean: Clean Flutter pub cache\n'
            '- flutter_build: Build app for platform (requires buildTarget)\n'
            '- flutter_run: Run the Flutter app (optional device param)\n\n'
            '⚙️ CODE GENERATION (build_runner):\n'
            '- build_runner_build: Generate code once\n'
            '- build_runner_watch: Watch and regenerate on changes\n'
            '- build_runner_clean: Clean generated files',
      )),
      'package': string().meta(MetadataEntry(
        description: 'Package name. Required for: pub_add, pub_remove. '
            'Optional for: pub_upgrade, pub_downgrade (if not specified, applies to all packages)',
      )),
      'version': string().meta(MetadataEntry(
        description:
            'version constraint (e.g., "^1.0.0", "1.2.3"). If not provided, uses latest compatible version.',
      )),
      'isDev': boolean().meta(MetadataEntry(
        description:
            'Whether to add package as dev dependency (only for pub_add). Default: false',
      )),
      'apply': boolean().meta(MetadataEntry(
        description:
            'Whether to apply fixes automatically (only for dart_fix). '
            'If false, runs in dry-run mode. Default: false',
      )),
      'buildTarget': string().meta(MetadataEntry(
        description: 'Build target platform (required for flutter_build). '
            'Options: apk, appbundle, ios, web, macos, windows, linux',
      )),
      'device': string().meta(MetadataEntry(
        description: 'Device ID to run on (optional for flutter_run). '
            'Use "chrome", device ID, or omit for default device',
      )),
      'testPath': string().meta(MetadataEntry(
        description:
            'Specific test file or directory path (optional for flutter_test). '
            'If not specified, runs all tests',
      )),
      'deleteConflicting': boolean().meta(MetadataEntry(
        description:
            'Delete conflicting outputs (only for build_runner_build). '
            'Use when build fails due to conflicts. Default: false',
      )),
    }).optionals([
      'package',
      'isDev',
      'apply',
      'buildTarget',
      'device',
      'testPath',
      'deleteConflicting',
      'version',
    ]).toJsonSchema(),
    func: (input) async {
      final result = await commandService.executeCommand(
        command: input.command,
        package: input.package,
        isDev: input.isDev,
        apply: input.apply,
        buildTarget: input.buildTarget,
        device: input.device,
        testPath: input.testPath,
        deleteConflicting: input.deleteConflicting,
        version: input.version,
      );
      return result.message;
    },
    getInputFromJson: RunCommandInput.fromJson,
  );
}
