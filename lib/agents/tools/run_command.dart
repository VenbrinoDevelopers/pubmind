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
        'Run common Dart/Flutter pub commands. Use this for maintenance tasks like cleaning, '
        'upgrading, removing packages, or checking outdated dependencies.',
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
        description: 'Command to run. Options:\n'
            '- pub_get: Fetch dependencies\n'
            '- pub_upgrade: Upgrade all or specific package\n'
            '- pub_downgrade: Downgrade all or specific package\n'
            '- pub_outdated: Check for outdated packages\n'
            '- pub_remove: Remove a package\n'
            '- flutter_clean: Clean Flutter build files',
      )),
      'package': string().meta(MetadataEntry(
        description:
            'Package name (required for pub_remove, optional for pub_upgrade/pub_downgrade)',
      )),
    }).optionals([
      'package',
    ]).toJsonSchema(),
    func: (input) async {
      final result = await commandService.executeCommand(
        command: input.command,
        package: input.package,
      );
      return result.message;
    },
    getInputFromJson: RunCommandInput.fromJson,
  );
}
