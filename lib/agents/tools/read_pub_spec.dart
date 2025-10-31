import 'dart:io';
import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class ReadPubspecInput {
  const ReadPubspecInput();

  ReadPubspecInput.fromJson(Map<String, dynamic> json) : this();
}

Tool createReadPubspecTool({required String projectDirectory}) {
  return Tool.fromFunction<ReadPubspecInput, String>(
    name: 'read_pubspec',
    description:
        'Read and parse the project\'s pubspec.yaml file to understand current state. '
        'Returns: project name, version, description, SDK constraints, all dependencies, and dev dependencies. '
        'CRITICAL: Call this FIRST before any package recommendations to understand existing dependencies, '
        'avoid duplicates, and check for potential conflicts. Essential for maintaining project integrity.',
    inputJsonSchema: object({}).toJsonSchema(),
    func: (ReadPubspecInput input) async {
      final pubspecFile = File(path.join(projectDirectory, 'pubspec.yaml'));

      if (!pubspecFile.existsSync()) {
        return 'Error: pubspec.yaml not found in $projectDirectory';
      }

      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as Map;

      final dependencies = _extractDependencies(yaml['dependencies']);
      final devDependencies = _extractDependencies(yaml['dev_dependencies']);

      final result = '''
Project Name: ${yaml['name'] ?? 'unknown'}
Version: ${yaml['version']?.toString() ?? 'unknown'}
Description: ${yaml['description'] ?? 'No description'}
SDK Constraint: ${yaml['environment']?['sdk']?.toString() ?? 'unknown'}

Dependencies (${dependencies.length}):
${dependencies.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}

Dev Dependencies (${devDependencies.length}):
${devDependencies.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}
''';

      return result;
    },
    getInputFromJson: (json) => ReadPubspecInput.fromJson(json),
    handleToolError: (e) {
      return 'Read pubspec tool error : ${e.toString()}';
    },
  );
}

Map<String, String> _extractDependencies(dynamic deps) {
  if (deps == null) return {};

  final map = <String, String>{};
  final depsMap = deps as Map;

  for (final entry in depsMap.entries) {
    final key = entry.key.toString();
    final value = entry.value;

    if (value is String) {
      map[key] = value;
    } else if (value is Map) {
      if (value.containsKey('version')) {
        map[key] = value['version'].toString();
      } else if (value.containsKey('path')) {
        map[key] = 'path: ${value['path']}';
      } else if (value.containsKey('git')) {
        map[key] = 'git';
      } else {
        map[key] = 'sdk';
      }
    }
  }

  return map;
}
