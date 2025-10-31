import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pub_api_client/pub_api_client.dart';

class SearchPackagesInput {
  const SearchPackagesInput({
    required this.query,
    this.limit = 3,
  });

  final String query;
  final int limit;

  SearchPackagesInput.fromJson(Map<String, dynamic> json)
      : this(
          query: json['query'] as String,
          limit: json['limit'] as int? ?? 3,
        );
}

Tool createSearchPackagesTool({PubClient? client}) {
  final pubClient = client ?? PubClient();

  return Tool.fromFunction<SearchPackagesInput, String>(
    name: 'search_packages',
    description: 'Search packages on pub.dev by keyword.',
    inputJsonSchema: object({
      'query': string().min(1).meta(MetadataEntry(description: 'Search query')),
      'limit': number()
          .positive()
          .meta(MetadataEntry(description: 'Number of results to return')),
    }).optionals(['limit']).toJsonSchema(),
    func: (SearchPackagesInput input) async {
      final results = await pubClient.search(input.query);
      final packages = results.packages.take(input.limit).toList();

      if (packages.isEmpty) {
        return 'No packages found for "${input.query}"';
      }

      return packages.asMap().entries.map((e) {
        final i = e.key + 1;
        final pkg = e.value.package;
        return '$i. $pkg\n   URL: https://pub.dev/packages/$pkg';
      }).join('\n\n');
    },
    getInputFromJson: (json) => SearchPackagesInput.fromJson(json),
    handleToolError: (e) {
      return 'Search packages tool error : ${e.toString()}';
    },
  );
}
