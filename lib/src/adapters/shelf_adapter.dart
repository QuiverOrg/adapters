import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../detectors/shelf_detector.dart';
import '../models/framework_info.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

class ShelfAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'shelf';
  @override
  String get displayName => 'Shelf';
  @override
  FrameworkDetector get detector => ShelfDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);
    final entrypoint = findEntrypoint(context.projectRoot);
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
        name: 'shelf',
        version: PubspecUtils.getDependencyVersion(pubspec, 'shelf'),
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
}
