import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../core/exceptions.dart';
import '../detectors/dart_detector.dart';
import '../models/framework_info.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

/// Catch-all adapter for any Dart server project that doesn't
/// match a specific framework. Handles raw dart:io HttpServer,
/// Shelf Plus, Vania, or any custom Dart backend.
class DartAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'dart';
  @override
  String get displayName => 'Dart';
  @override
  FrameworkDetector get detector => DartDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);

    final entrypoint = _findAnyEntrypoint(context.projectRoot);
    if (context.verbose) stdout.writeln('  Entrypoint: $entrypoint');

    checkPortUsage(context.projectRoot, entrypoint, context.verbose);

    if (context.verbose) stdout.writeln('  Resolving dependencies...');
    await ProcessUtils.pubGet(context.projectRoot, verbose: context.verbose);

    if (context.verbose) stdout.writeln('  Compiling to native binary...');
    await ProcessUtils.compileExe(
      entrypoint: '${context.projectRoot}/$entrypoint',
      outputPath: '${context.serverOutputDir}/main',
      workingDirectory: context.projectRoot,
      verbose: context.verbose,
    );

    final envVars = detectEnvVars(context.projectRoot, entrypoint);
    final serverConfig = ServerConfig(envVarsInUse: envVars);
    await serverConfig.writeTo(context.serverOutputDir);

    final (hasStatic, staticCount) = await copyStaticAssets(
      context.projectRoot,
      context.staticOutputDir,
      verbose: context.verbose,
    );

    final output = BuildOutput(
      framework: FrameworkInfo(
        name: 'dart',
        version: PubspecUtils.getDartSdkConstraint(pubspec),
      ),
      dart: DartInfo(
        version: context.dartVersion,
        channel: context.dartChannel,
      ),
      hasServer: true,
      serverConfig: serverConfig,
      hasStatic: hasStatic,
      staticFileCount: staticCount,
      routes: buildRoutes(hasStatic: hasStatic),
      envVarsInUse: envVars,
    );

    final configFile = File(context.configOutputPath);
    await configFile.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(output.toConfigJson()),
    );
    return output;
  }

  /// More aggressive entrypoint search than the standard helper.
  String _findAnyEntrypoint(String projectRoot) {
    for (final name in ['bin/server.dart', 'bin/main.dart']) {
      if (File('$projectRoot/$name').existsSync()) return name;
    }
    final binDir = Directory('$projectRoot/bin');
    if (binDir.existsSync()) {
      for (final entity in binDir.listSync()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          return 'bin/${entity.uri.pathSegments.last}';
        }
      }
    }
    throw const BuildException(
      'No server entrypoint found in bin/',
      hint: 'Create bin/server.dart or bin/main.dart',
    );
  }
}
