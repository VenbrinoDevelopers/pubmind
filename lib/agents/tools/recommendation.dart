import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/core/recommendation_engine.dart';

/// Input structure for recommendation tool
class RecommendPackagesInput {
  const RecommendPackagesInput({
    required this.packages,
    this.userQuery,
  });

  final List<Map<String, dynamic>> packages;
  final String? userQuery;

  RecommendPackagesInput.fromJson(Map<String, dynamic> json)
      : packages = (json['packages'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        userQuery = json['userQuery'] as String?;
}

Tool createRecommendPackagesTool() {
  return Tool.fromFunction<RecommendPackagesInput, String>(
    name: 'recommend_packages',
    description:
        'Compare multiple packages and recommend the best option based on metrics AND how well they match the user\'s requirements. '
        'You should analyze each package\'s description/features and assign a descriptionScore (0-1) based on relevance. '
        'Pass this score along with other metrics. Higher descriptionScore means better match to user needs.',
    inputJsonSchema: object({
      'packages': object({
        'name':
            string().min(1).meta(MetadataEntry(description: 'Package name')),
        'pubPoints':
            number().meta(MetadataEntry(description: 'Pub points scored')),
        'popularity':
            number().meta(MetadataEntry(description: 'Popularity percentage')),
        'likes': number().meta(MetadataEntry(description: 'Number of likes')),
        'descriptionScore': number()
            .between(0, 1,
                message:
                    'Description score must be between 0-1 it can be 0.1,0.2.0.5,0.9 and so on')
            .meta(MetadataEntry(
                description:
                    'How well this package matches user requirements (0-1) it can be 0.1,0.2.0.5,0.9 and so on. Analyze the package description/features.')),
        'publisher':
            string().meta(MetadataEntry(description: 'Package publisher')),
        'lastUpdated': string()
            .meta(MetadataEntry(description: 'Last updated date in ISO8601')),
      })
          .optionals(['publisher', 'lastUpdated', 'descriptionScore'])
          .list()
          .meta(MetadataEntry(
              description: 'List of packages with their metrics')),
      'userQuery': string().meta(
          MetadataEntry(description: 'Original user search query for context')),
    }).optionals(['userQuery']).toJsonSchema(),
    func: (RecommendPackagesInput input) async {
      if (input.packages.isEmpty) {
        return 'No packages provided to compare.';
      }

      final metricsList = <PackageMetrics>[];

      for (final pkgData in input.packages) {
        try {
          metricsList.add(PackageMetrics.fromPackageData(
            name: pkgData['name'] as String,
            grantedPoints: pkgData['pubPoints'] as int? ?? 0,
            maxPoints: 140,
            popularity: pkgData['popularity'] as int? ?? 0,
            likes: pkgData['likes'] as int? ?? 0,
            publisher: pkgData['publisher'] as String?,
            lastUpdated: pkgData['lastUpdated'] != null
                ? DateTime.tryParse(pkgData['lastUpdated'] as String)
                : null,
            descriptionScore: (pkgData['descriptionScore'] as num?)?.toDouble(),
          ));
        } catch (e) {
          return '❌ Invalid package data: $pkgData\nError: $e';
        }
      }

      return PackageRecommendationEngine.comparePackages(metricsList);
    },
    getInputFromJson: (json) => RecommendPackagesInput.fromJson(json),
    handleToolError: (e) {
      return 'Recommend packages tool error: ${e.toString()}';
    },
  );
}
