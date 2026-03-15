import '../models/framework_info.dart';
import '../models/route_config.dart';
import '../models/server_config.dart';

/// Result of a successful adapter build.
class BuildOutput {
  final int version;
  final FrameworkInfo? framework;
  final DartInfo dart;
  final bool hasServer;
  final ServerConfig? serverConfig;
  final bool hasStatic;
  final int staticFileCount;
  final List<RouteConfig> routes;
  final List<String> envVarsInUse;

  const BuildOutput({
    this.version = 1,
    this.framework,
    required this.dart,
    this.hasServer = false,
    this.serverConfig,
    this.hasStatic = false,
    this.staticFileCount = 0,
    this.routes = const [],
    this.envVarsInUse = const [],
  });

  Map<String, dynamic> toConfigJson() => {
    'version': version,
    'framework': ?framework?.toJson(),
    'dart': dart.toJson(),
    if (routes.isNotEmpty) 'routes': routes.map((r) => r.toJson()).toList(),
    if (envVarsInUse.isNotEmpty) 'env': envVarsInUse,
  };
}

class DartInfo {
  final String version;
  final String channel;

  const DartInfo({required this.version, this.channel = 'stable'});

  Map<String, dynamic> toJson() => {'version': version, 'channel': channel};
}
