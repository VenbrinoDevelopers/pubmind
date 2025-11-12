enum PubCommand {
  // Existing commands
  pubGet,
  pubUpgrade,
  pubDowngrade,
  pubOutdated,
  pubRemove,
  flutterClean,
  
  // New dependency management commands
  pubAdd,
  pubDeps,
  pubCacheRepair,
  
  // Code analysis & quality commands
  dartAnalyze,
  dartFix,
  dartFormat,
  
  // Testing commands
  flutterTest,
  flutterTestCoverage,
  
  // Flutter-specific commands
  flutterDoctor,
  flutterUpgrade,
  flutterPubCacheClean,
  flutterBuild,
  flutterRun,
  
  // Build runner commands
  buildRunnerBuild,
  buildRunnerWatch,
  buildRunnerClean,
}
