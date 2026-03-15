import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../core/exceptions.dart';
import '../detectors/dart_frog_detector.dart';
import '../models/framework_info.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

class DartFrogAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'dart_frog';
  @override
  String get displayName => 'Dart Frog';
  @override
  FrameworkDetector get detector => DartFrogDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);

    await _ensureCli(context);

    if (context.verbose) stdout.writeln('  Resolving dependencies...');
    await ProcessUtils.pubGet(context.projectRoot, verbose: context.verbose);

    if (context.verbose) stdout.writeln('  Running dart_frog build...');
    await ProcessUtils.run(
      'dart_frog',
      ['build'],
      workingDirectory: context.projectRoot,
      verbose: context.verbose,
      errorMessage: 'dart_frog build failed',
    );

    final generated = _findGenerated(context.projectRoot);
    if (context.verbose) stdout.writeln('  Generated: $generated');

    if (context.verbose) stdout.writeln('  Compiling to native binary...');
    await ProcessUtils.compileExe(
      entrypoint: generated,
      outputPath: '${context.serverOutputDir}/main',
      workingDirectory: context.projectRoot,
      verbose: context.verbose,
    );

    const serverConfig = ServerConfig();
    await serverConfig.writeTo(context.serverOutputDir);

    final (hasStatic, staticCount) = await copyStaticAssets(
      context.projectRoot,
      context.staticOutputDir,
      verbose: context.verbose,
    );

    final routes = _discoverRoutes(context.projectRoot);
    if (context.verbose) stdout.writeln('  Discovered ${routes.length} routes');

    final output = BuildOutput(
      framework: FrameworkInfo(
        name: 'dart_frog',
        version: PubspecUtils.getDependencyVersion(pubspec, 'dart_frog'),
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
    );

    final configFile = File(context.configOutputPath);
    await configFile.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(output.toConfigJson()),
    );
    return output;
  }

  @override
  Future<void> cleanup(BuildContext context) async {
    final dir = Directory('${context.projectRoot}/build');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> _ensureCli(BuildContext context) async {
    try {
      await ProcessUtils.run('dart_frog', ['--version']);
    } on CompilationException {
      if (context.verbose) stdout.writeln('  Installing dart_frog_cli...');
      await ProcessUtils.run(
        'dart',
        ['pub', 'global', 'activate', 'dart_frog_cli'],
        verbose: context.verbose,
        errorMessage: 'Failed to install dart_frog_cli',
      );
    }
  }

  String _findGenerated(String projectRoot) {
    for (final path in [
      '$projectRoot/build/bin/server.dart',
      '$projectRoot/build/server.dart',
    ]) {
      if (File(path).existsSync()) return path;
    }
    final buildDir = Directory('$projectRoot/build');
    if (buildDir.existsSync()) {
      for (final e in buildDir.listSync(recursive: true)) {
        if (e is File && e.path.endsWith('server.dart')) return e.path;
      }
    }
    throw const BuildException(
      'dart_frog build did not produce a server entrypoint',
      hint: 'Ensure dart_frog_cli is installed and your project is valid',
    );
  }

  List<String> _discoverRoutes(String projectRoot) {
    final routesDir = Directory('$projectRoot/routes');
    if (!routesDir.existsSync()) return [];
    final routes = <String>[];
    for (final e in routesDir.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart')) {
        var route = e.path
            .substring(routesDir.path.length)
            .replaceAll(r'\', '/')
            .replaceAll('.dart', '');
        if (route.endsWith('/index')) {
          route = route.substring(0, route.length - 6);
        }
        if (route.isEmpty) route = '/';
        route = route.replaceAllMapped(
          RegExp(r'\[(\w+)\]'),
          (m) => ':${m.group(1)}',
        );
        routes.add(route);
      }
    }
    return routes..sort();
  }
}
