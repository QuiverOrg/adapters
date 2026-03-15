import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../detectors/conduit_detector.dart';
import '../models/framework_info.dart';
import '../models/route_config.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

class ConduitAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'conduit';
  @override
  String get displayName => 'Conduit';
  @override
  FrameworkDetector get detector => ConduitDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);

    if (context.verbose) stdout.writeln('  Resolving dependencies...');
    await ProcessUtils.pubGet(context.projectRoot, verbose: context.verbose);

    final entrypoint = findEntrypoint(context.projectRoot, [
      'bin/main.dart',
      'bin/server.dart',
    ]);
    if (context.verbose) stdout.writeln('  Entrypoint: $entrypoint');

    if (context.verbose) stdout.writeln('  Compiling to native binary...');
    await ProcessUtils.compileExe(
      entrypoint: '${context.projectRoot}/$entrypoint',
      outputPath: '${context.serverOutputDir}/main',
      workingDirectory: context.projectRoot,
      verbose: context.verbose,
    );

    // Copy config files for runtime access
    for (final name in ['config.yaml', 'config.src.yaml']) {
      final file = File('${context.projectRoot}/$name');
      if (file.existsSync()) {
        if (context.verbose) stdout.writeln('  Copying $name...');
        await file.copy('${context.serverOutputDir}/$name');
      }
    }

    const envVars = _conduitEnvVars;
    const serverConfig = ServerConfig(memory: 512, envVarsInUse: envVars);
    await serverConfig.writeTo(context.serverOutputDir);

    final output = BuildOutput(
      framework: FrameworkInfo(
        name: 'conduit',
        version:
            PubspecUtils.getDependencyVersion(pubspec, 'conduit') ??
            PubspecUtils.getDependencyVersion(pubspec, 'conduit_core'),
      ),
      dart: DartInfo(
        version: context.dartVersion,
        channel: context.dartChannel,
      ),
      hasServer: true,
      serverConfig: serverConfig,
      routes: const [RouteConfig(src: '/(.*)', dest: '/server')],
      envVarsInUse: envVars,
    );

    final configFile = File(context.configOutputPath);
    await configFile.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(output.toConfigJson()),
    );
    return output;
  }

  static const _conduitEnvVars = [
    'DATABASE_HOST',
    'DATABASE_PORT',
    'DATABASE_NAME',
    'DATABASE_USERNAME',
    'DATABASE_PASSWORD',
  ];
}
