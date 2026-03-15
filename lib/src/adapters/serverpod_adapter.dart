import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../core/exceptions.dart';
import '../detectors/serverpod_detector.dart';
import '../models/framework_info.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

class ServerpodAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'serverpod';
  @override
  String get displayName => 'Serverpod';
  @override
  FrameworkDetector get detector => ServerpodDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);

    if (context.verbose) stdout.writeln('  Resolving dependencies...');
    await ProcessUtils.pubGet(context.projectRoot, verbose: context.verbose);

    // Run code generation if CLI is available
    try {
      await ProcessUtils.run(
        'serverpod',
        ['generate'],
        workingDirectory: context.projectRoot,
        verbose: context.verbose,
      );
    } on CompilationException {
      if (context.verbose) {
        stdout.writeln('  ⚠ serverpod CLI not found, skipping codegen');
      }
    }

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

    // Copy config/ directory for runtime access
    final configDir = Directory('${context.projectRoot}/config');
    if (configDir.existsSync()) {
      if (context.verbose) stdout.writeln('  Copying config/ directory...');
      await ProcessUtils.copyDirectory(
        configDir,
        Directory('${context.serverOutputDir}/config'),
      );
    }

    const envVars = _serverpodEnvVars;
    const serverConfig = ServerConfig(memory: 512, envVarsInUse: envVars);
    await serverConfig.writeTo(context.serverOutputDir);

    final (hasStatic, staticCount) = await copyStaticAssets(
      context.projectRoot,
      context.staticOutputDir,
      dirs: ['web', 'public'],
      verbose: context.verbose,
    );

    final output = BuildOutput(
      framework: FrameworkInfo(
        name: 'serverpod',
        version: PubspecUtils.getDependencyVersion(pubspec, 'serverpod'),
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

  static const _serverpodEnvVars = [
    'SERVERPOD_DATABASE_HOST',
    'SERVERPOD_DATABASE_PORT',
    'SERVERPOD_DATABASE_NAME',
    'SERVERPOD_DATABASE_USER',
    'SERVERPOD_DATABASE_PASSWORD',
    'SERVERPOD_REDIS_HOST',
    'SERVERPOD_REDIS_PORT',
  ];
}
