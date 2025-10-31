import 'dart:convert';
import 'package:acanthis/acanthis.dart';
import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';

class GetPackageInfoInput {
  const GetPackageInfoInput({required this.package});
  final String package;

  factory GetPackageInfoInput.fromJson(Map<String, dynamic> json) =>
      GetPackageInfoInput(package: json['package'] as String);
}

Tool createGetPackageInfoTool() {
  return Tool.fromFunction<GetPackageInfoInput, String>(
    name: 'get_package_info',
    description:
        'Get detailed information about a specific Dart package from pub.dev, including version, description, homepage, repository, pub points, popularity, likes, SDK constraint, dependencies, and dev dependencies. ',
    inputJsonSchema: object({
      'package': string().min(1).meta(
          const MetadataEntry(description: 'Package name to get info for')),
    }).toJsonSchema(),
    func: (GetPackageInfoInput input) async =>
        await _fetchPackageInfo(input.package),
    getInputFromJson: (json) => GetPackageInfoInput.fromJson(json),
  );
}

Future<String> _fetchPackageInfo(String name) async {
  final base = 'https://pub.dev/api/packages';
  final infoUri = Uri.parse('$base/$name');
  final scoreUri = Uri.parse('$base/$name/score');

  final infoResp = await http.get(infoUri);
  if (infoResp.statusCode != 200) {
    return 'Package "$name" not found (HTTP ${infoResp.statusCode}).';
  }

  final Map<String, dynamic> info = json.decode(infoResp.body);
  final latest = info['latest'] as Map<String, dynamic>;
  final pubspec = latest['pubspec'] as Map<String, dynamic>;

  Map<String, dynamic> score = {};
  final scoreResp = await http.get(scoreUri);
  if (scoreResp.statusCode == 200) {
    score = json.decode(scoreResp.body) as Map<String, dynamic>;
  }

  final version = latest['version'] as String? ?? 'unknown';
  final description = pubspec['description'] as String? ?? 'No description';
  final homepage = pubspec['homepage'] as String? ?? 'N/A';
  final repository = pubspec['repository'] as String? ?? 'N/A';
  final sdk =
      (pubspec['environment'] as Map<String, dynamic>?)?['sdk'] as String? ??
          'N/A';

  final deps =
      (pubspec['dependencies'] as Map<String, dynamic>?)?.keys.toList() ??
          <String>[];
  final devDeps =
      (pubspec['dev_dependencies'] as Map<String, dynamic>?)?.keys.toList() ??
          <String>[];

  final granted = score['grantedPoints'] as int? ?? 0;
  final max = score['maxPoints'] as int? ?? 0;
  final popularity = (score['popularityScore'] as num?) ?? 0;
  final likes = score['likeCount'] as int? ?? 0;

  final buffer = StringBuffer()
    ..writeln('Package: $name')
    ..writeln('Version: $version')
    ..writeln('Description: $description')
    ..writeln('Homepage: $homepage')
    ..writeln('Repository: $repository')
    ..writeln('Pub Points: $granted/$max')
    ..writeln('Popularity: ${(popularity * 100).round()}%')
    ..writeln('Likes: $likes')
    ..writeln('SDK Constraint: $sdk')
    ..writeln('Dependencies: ${deps.isEmpty ? 'None' : deps.join(', ')}')
    ..writeln(
        'Dev Dependencies: ${devDeps.isEmpty ? 'None' : devDeps.join(', ')}');

  return buffer.toString().trim();
}
