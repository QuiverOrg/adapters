import 'dart:convert';
import 'dart:io';

import '../core/adapter.dart';
import '../core/build_context.dart';
import '../core/build_output.dart';
import '../core/detector.dart';
import '../core/exceptions.dart';
import '../detectors/jaspr_detector.dart';
import '../models/framework_info.dart';
import '../models/route_config.dart';
import '../models/server_config.dart';
import '../utils/process_utils.dart';
import '../utils/pubspec_utils.dart';
import '_helpers.dart';

class JasprAdapter extends QuiverAdapter with AdapterHelpers {
  @override
  String get name => 'jaspr';
  @override
  String get displayName => 'Jaspr';
  @override
  FrameworkDetector get detector => JasprDetector();

  @override
  Future<BuildOutput> build(BuildContext context) async {
    final pubspec = PubspecUtils.readPubspec(context.projectRoot);

    if (context.verbose) stdout.writeln('  Resolving dependencies...');
    await ProcessUtils.pubGet(context.projectRoot, verbose: context.verbose);

    final isSSR = _isSSRMode(context.projectRoot);
    if (context.verbose) stdout.writeln('  Mode: ${isSSR ? "SSR" : "SSG"}');

    if (context.verbose) stdout.writeln('  Running jaspr build...');
    await _runBuild(context, isSSR: isSSR);

    var hasServer = false;
    ServerConfig? serverConfig;
    var hasStatic = false;
    var staticCount = 0;

    if (isSSR) {
      final generated = _findGeneratedServer(context.projectRoot);
      if (context.verbose) stdout.writeln('  Compiling SSR server...');
      await ProcessUtils.compileExe(
        entrypoint: generated,
        outputPath: '${context.serverOutputDir}/main',
        workingDirectory: context.projectRoot,
        verbose: context.verbose,
      );
      serverConfig = const ServerConfig();
      await serverConfig.writeTo(context.serverOutputDir);
      hasServer = true;

      // SSR may also produce client-side JS bundles
      for (final sub in ['web', 'static']) {
        final dir = Directory('${context.projectRoot}/build/jaspr/$sub');
        if (dir.existsSync()) {
          await ProcessUtils.copyDirectory(
            dir,
            Directory(context.staticOutputDir),
          );
          hasStatic = true;
          staticCount = await countFiles(Directory(context.staticOutputDir));
          break;
        }
      }
    } else {
      // SSG: entire build output is static
      final buildDir = _findBuildDir(context.projectRoot);
      if (context.verbose) stdout.writeln('  Copying generated site...');
      await ProcessUtils.copyDirectory(
        buildDir,
        Directory(context.staticOutputDir),
      );
      hasStatic = true;
      staticCount = await countFiles(Directory(context.staticOutputDir));
    }

    final routes = <RouteConfig>[
      if (hasStatic && hasServer)
        const RouteConfig(
          src:
              r'/(.+\.(?:html|css|js|ico|png|jpg|jpeg|svg|gif|woff2?|ttf|eot|json))$',
          dest: r'/static/$1',
        ),
      if (hasServer) const RouteConfig(src: '/(.*)', dest: '/server'),
      if (!hasServer && hasStatic)
        const RouteConfig(src: '/(.*)', dest: r'/static/$1'),
    ];

    final output = BuildOutput(
      framework: FrameworkInfo(
        name: 'jaspr',
        version: PubspecUtils.getDependencyVersion(pubspec, 'jaspr'),
      ),
      dart: DartInfo(
        version: context.dartVersion,
        channel: context.dartChannel,
      ),
      hasServer: hasServer,
      serverConfig: serverConfig,
      hasStatic: hasStatic,
      staticFileCount: staticCount,
      routes: routes,
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

  bool _isSSRMode(String projectRoot) {
    final content = File('$projectRoot/pubspec.yaml').readAsStringSync();
    return content.contains('mode: server') ||
        content.contains('uses_server_rendering: true') ||
        File('$projectRoot/lib/main.server.dart').existsSync();
  }

  Future<void> _runBuild(BuildContext context, {required bool isSSR}) async {
    final args = [
      'build',
      if (isSSR) ...['--mode', 'server'],
    ];
    try {
      await ProcessUtils.run(
        'jaspr',
        args,
        workingDirectory: context.projectRoot,
        verbose: context.verbose,
      );
    } on CompilationException {
      await ProcessUtils.run(
        'dart',
        ['run', 'jaspr', ...args],
        workingDirectory: context.projectRoot,
        verbose: context.verbose,
        errorMessage: 'jaspr build failed',
      );
    }
  }

  String _findGeneratedServer(String projectRoot) {
    for (final p in [
      'build/jaspr/app.dart',
      'build/jaspr/server.dart',
      'build/server.dart',
    ]) {
      if (File('$projectRoot/$p').existsSync()) return '$projectRoot/$p';
    }
    throw const BuildException(
      'Jaspr SSR build did not produce a server entrypoint',
    );
  }

  Directory _findBuildDir(String projectRoot) {
    for (final p in ['build/jaspr', 'build/web', 'build']) {
      final dir = Directory('$projectRoot/$p');
      if (dir.existsSync() && dir.listSync().isNotEmpty) return dir;
    }
    throw const BuildException('Jaspr build did not produce output');
  }
}
