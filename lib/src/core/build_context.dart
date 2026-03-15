/// Input to every [QuiverAdapter.build] invocation.
class BuildContext {
  final String projectRoot;
  final String outputDir;
  final DeployEnvironment environment;
  final String dartVersion;
  final String dartChannel;
  final bool verbose;

  const BuildContext({
    required this.projectRoot,
    required this.outputDir,
    required this.dartVersion,
    this.environment = DeployEnvironment.production,
    this.dartChannel = 'stable',
    this.verbose = false,
  });

  String get serverOutputDir => '$outputDir/server';
  String get staticOutputDir => '$outputDir/static';
  String get functionsOutputDir => '$outputDir/functions';
  String get configOutputPath => '$outputDir/config.json';
}

enum DeployEnvironment {
  production,
  preview,
  development;

  @override
  String toString() => name;
}
