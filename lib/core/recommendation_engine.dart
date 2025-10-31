class PackageMetrics {
  final String name;
  final int pubPoints;
  final int popularity;
  final int likes;
  final double recencyScore; // 0-1 based on last update
  final double
      descriptionScore; // 0-1 based on how well it matches user's needs
  final bool isOfficial;
  final List<String> strengths;
  final List<String> weaknesses;

  PackageMetrics({
    required this.name,
    required this.pubPoints,
    required this.popularity,
    required this.likes,
    this.recencyScore = 1.0,
    this.descriptionScore = 0.0,
    this.isOfficial = false,
    this.strengths = const [],
    this.weaknesses = const [],
  });

  double get compositeScore =>
      PackageRecommendationEngine.calculateCompositeScore(this);

  static PackageMetrics fromPackageData({
    required String name,
    required int grantedPoints,
    required int maxPoints,
    required int popularity,
    required int likes,
    String? publisher,
    DateTime? lastUpdated,
    double? descriptionScore, // Add this parameter
  }) {
    final strengths = <String>[];
    final weaknesses = <String>[];

    if (grantedPoints >= 130) strengths.add('High quality');
    if (popularity >= 90) strengths.add('Very popular');
    if (likes > 500) strengths.add('Community favorite');
    if (publisher != null &&
        (publisher.contains('dart.dev') || publisher.contains('flutter.dev'))) {
      strengths.add('Official package');
    }
    if (descriptionScore != null && descriptionScore >= 0.8) {
      strengths.add('Perfect match for requirements');
    }

    if (grantedPoints < 100) weaknesses.add('Lower quality score');
    if (popularity < 50) weaknesses.add('Less popular');
    if (likes < 50) weaknesses.add('Limited community adoption');
    if (descriptionScore != null && descriptionScore < 0.5) {
      weaknesses.add('May not fully match requirements');
    }

    double recencyScore = 1.0;
    if (lastUpdated != null) {
      final daysSinceUpdate = DateTime.now().difference(lastUpdated).inDays;
      if (daysSinceUpdate > 730) {
        recencyScore = 0.3;
        weaknesses.add('Not recently updated');
      } else if (daysSinceUpdate > 365) {
        recencyScore = 0.6;
      } else if (daysSinceUpdate > 180) {
        recencyScore = 0.8;
      }
    }

    return PackageMetrics(
      name: name,
      pubPoints: grantedPoints,
      popularity: popularity,
      likes: likes,
      recencyScore: recencyScore,
      descriptionScore: descriptionScore ?? 0.0,
      isOfficial: publisher != null &&
          (publisher.contains('dart.dev') || publisher.contains('flutter.dev')),
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }
}

class PackageRecommendationEngine {
  static double calculateCompositeScore(PackageMetrics metrics) {
    // Weighted scoring: Description Match (35%), Pub Points (25%), Popularity (20%), Likes (10%), Recency (10%)
    final descriptionScore = metrics.descriptionScore * 35;
    final pubPointsScore = (metrics.pubPoints / 140) * 25;
    final popularityScore = (metrics.popularity / 100) * 20;
    final likesScore = (metrics.likes / 1000).clamp(0, 1) * 10;
    final recencyScore = metrics.recencyScore * 10;

    return descriptionScore +
        pubPointsScore +
        popularityScore +
        likesScore +
        recencyScore;
  }

  static String comparePackages(List<PackageMetrics> packages) {
    if (packages.isEmpty) return 'No packages to compare.';

    final buffer = StringBuffer();
    buffer.writeln('📊 Package Comparison');
    buffer.writeln('═' * 60);

    packages.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    for (var i = 0; i < packages.length; i++) {
      final pkg = packages[i];
      final rank = i + 1;
      final medal = rank == 1
          ? '🥇'
          : rank == 2
              ? '🥈'
              : rank == 3
                  ? '🥉'
                  : '  ';

      buffer.writeln('\n$medal Rank $rank: ${pkg.name}');
      buffer.writeln(
          '   Overall Score: ${pkg.compositeScore.toStringAsFixed(1)}/100');
      buffer.writeln(
          '   Requirements Match: ${(pkg.descriptionScore * 100).toStringAsFixed(0)}%');
      buffer.writeln('   Pub Points: ${pkg.pubPoints}/140');
      buffer.writeln('   Popularity: ${pkg.popularity}%');
      buffer.writeln('   Likes: ${pkg.likes}');

      if (pkg.strengths.isNotEmpty) {
        buffer.writeln('   ✅ Strengths: ${pkg.strengths.join(", ")}');
      }
      if (pkg.weaknesses.isNotEmpty) {
        buffer.writeln('   ⚠️  Weaknesses: ${pkg.weaknesses.join(", ")}');
      }
    }

    buffer.writeln('\n${'═' * 60}');
    buffer.writeln('🎯 Recommendation: ${packages.first.name}');
    buffer.writeln('   ${_getRecommendationReason(packages.first, packages)}');

    return buffer.toString();
  }

  static String _getRecommendationReason(
      PackageMetrics top, List<PackageMetrics> all) {
    final reasons = <String>[];

    if (top.descriptionScore >= 0.9) {
      reasons.add('Excellent match for your requirements');
    }
    if (top.pubPoints >= 130) {
      reasons.add('Excellent quality score');
    }
    if (top.popularity >= 90) {
      reasons.add('Highly popular in community');
    }
    if (top.likes >
        all.map((p) => p.likes).reduce((a, b) => a > b ? a : b) * 0.8) {
      reasons.add('Strong community approval');
    }
    if (top.isOfficial) {
      reasons.add('Official Dart/Flutter package');
    }

    return reasons.isEmpty ? 'Best overall metrics' : reasons.join(', ');
  }
}
