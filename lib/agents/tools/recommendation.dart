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
        'Intelligently compare multiple packages and recommend the best option based on comprehensive scoring. '
        'SCORING: Combines objective metrics (pub points, popularity, likes, maintenance) with YOUR analysis. '
        'YOU MUST: Assign descriptionScore (0.0-1.0) for each package based on how well it matches user requirements. '
        'HOW: Read each package description/features, analyze fit for user needs, assign honest score. '
        'Higher descriptionScore = better match. Be analytical and fair. '
        'Returns: Ranked list with total scores, detailed breakdown, and recommendation reasoning.',
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
                    'YOUR ANALYSIS: How well does this package match user requirements? '
                    '1.0=perfect, 0.8-0.9=excellent, 0.6-0.7=good, 0.4-0.5=partial, 0.0-0.3=poor. '
                    'Analyze package description and features carefully.')),
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
