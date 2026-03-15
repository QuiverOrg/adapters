import 'dart:io';
import '../core/exceptions.dart';
import '../models/route_config.dart';

/// Common logic shared across adapters.
mixin AdapterHelpers {
  /// Find a server entrypoint from common candidates.
  String findEntrypoint(
    String projectRoot, [
    List<String> candidates = const ['bin/server.dart', 'bin/main.dart'],
  ]) {
    for (final path in candidates) {
      if (File('$projectRoot/$path').existsSync()) return path;
    }
    throw const BuildException(
      'No server entrypoint found',
      hint: 'Create bin/server.dart or bin/main.dart',
    );
  }

  /// Check if entrypoint reads PORT from environment.
  void checkPortUsage(String projectRoot, String entrypoint, bool verbose) {
    final content = File('$projectRoot/$entrypoint').readAsStringSync();
    final readsPort =
        content.contains("Platform.environment['PORT']") ||
        content.contains('Platform.environment["PORT"]') ||
        content.contains("fromEnvironment('PORT')") ||
        content.contains('fromEnvironment("PORT")');
    if (!readsPort && verbose) {
      stdout.writeln(
        '  ⚠ Warning: $entrypoint may not read PORT from environment.\n'
        '    Quiver sets PORT at runtime. Ensure your server listens on it.',
      );
    }
  }

  /// Scan entrypoint for Platform.environment usage.
  List<String> detectEnvVars(String projectRoot, String entrypoint) {
    final content = File('$projectRoot/$entrypoint').readAsStringSync();
    final envVars = <String>{};
    final pattern = RegExp(
      r"Platform\.environment\['([A-Z_][A-Z0-9_]*)'\]|"
      r'Platform\.environment\["([A-Z_][A-Z0-9_]*)"\]',
    );
    for (final match in pattern.allMatches(content)) {
      final v = match.group(1) ?? match.group(2);
      if (v case final v? when v != 'PORT') envVars.add(v);
    }
    return envVars.toList()..sort();
  }

  /// Standard static file routing rules.
  List<RouteConfig> buildRoutes({required bool hasStatic}) => [
    if (hasStatic)
      const RouteConfig(
        src: r'/(.+\.(?:html|css|js|ico|png|jpg|jpeg|svg|gif|woff2?|ttf|eot))$',
        dest: r'/static/$1',
      ),
    const RouteConfig(src: '/(.*)', dest: '/server'),
  ];

  /// Copy first matching static directory to output.
  Future<(bool, int)> copyStaticAssets(
    String projectRoot,
    String staticOutputDir, {
    List<String> dirs = const ['public', 'web', 'static'],
    bool verbose = false,
  }) async {
    for (final dirName in dirs) {
      final dir = Directory('$projectRoot/$dirName');
      if (dir.existsSync()) {
        if (verbose) stdout.writeln('  Copying $dirName/ as static assets...');
        await _copyDir(dir, Directory(staticOutputDir));
        final count = await _countFiles(Directory(staticOutputDir));
        return (true, count);
      }
    }
    return (false, 0);
  }

  Future<int> countFiles(Directory dir) => _countFiles(dir);

  Future<int> _countFiles(Directory dir) async {
    var count = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) count++;
    }
    return count;
  }

  Future<void> _copyDir(Directory source, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final rel = entity.path.substring(source.path.length);
      final newPath = '${dest.path}$rel';
      if (entity is File) {
        await File(newPath).create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      }
    }
  }
}
