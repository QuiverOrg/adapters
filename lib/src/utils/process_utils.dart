import 'dart:io';
import '../core/exceptions.dart';

class ProcessUtils {
  static Future<void> pubGet(
    String projectRoot, {
    bool verbose = false,
  }) async => await run(
    'dart',
    ['pub', 'get'],
    workingDirectory: projectRoot,
    verbose: verbose,
    errorMessage: 'Failed to resolve dependencies',
  );

  static Future<void> compileExe({
    required String entrypoint,
    required String outputPath,
    String? workingDirectory,
    bool verbose = false,
  }) async {
    await Directory(outputPath).parent.create(recursive: true);
    await run(
      'dart',
      ['compile', 'exe', entrypoint, '-o', outputPath],
      workingDirectory: workingDirectory,
      verbose: verbose,
      errorMessage: 'Dart AOT compilation failed',
    );
    if (!File(outputPath).existsSync()) {
      throw BuildException('No binary produced at $outputPath');
    }
  }

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool verbose = false,
    String? errorMessage,
  }) async {
    if (verbose) stdout.writeln('  \$ $executable ${arguments.join(' ')}');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
    if (verbose && result.stdout.toString().isNotEmpty) {
      stdout.write(result.stdout);
    }
    if (result.exitCode != 0) {
      final stderr = result.stderr.toString();
      if (verbose && stderr.isNotEmpty) stdout.write(stderr);
      throw CompilationException(
        exitCode: result.exitCode,
        stderr: errorMessage != null ? '$errorMessage\n$stderr' : stderr,
      );
    }
    return result;
  }

  static Future<void> copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relativePath = entity.path.substring(source.path.length);
      final newPath = '${destination.path}$relativePath';
      if (entity is File) {
        await File(newPath).create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
      }
    }
  }
}
