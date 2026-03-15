import 'dart:convert';
import 'dart:io';

import 'exceptions.dart';

/// Validates `.quiver/output/` against the Build Output Spec.
class BuildValidator {
  static const maxFileSize = 50 * 1024 * 1024;
  static const maxTotalSize = 250 * 1024 * 1024;
  static const maxServerBinarySize = 100 * 1024 * 1024;
  static const maxStaticFileCount = 10000;

  static Future<List<String>> validate(String outputDir) async {
    final errors = <String>[];

    final configFile = File('$outputDir/config.json');
    if (!configFile.existsSync()) {
      errors.add('Missing config.json');
      return errors;
    }

    Map<String, dynamic> config;
    try {
      config =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      errors.add('config.json is not valid JSON: $e');
      return errors;
    }

    if (config['version'] != 1) {
      errors.add('config.version must be 1, got ${config['version']}');
    }
    if (config['dart'] == null) {
      errors.add('config.dart is required');
    }

    final serverDir = Directory('$outputDir/server');
    if (serverDir.existsSync()) {
      final binary = File('$outputDir/server/main');
      if (!binary.existsSync()) {
        errors.add('server/ exists but server/main binary is missing');
      } else if (binary.lengthSync() > maxServerBinarySize) {
        errors.add('server/main exceeds ${_fmt(maxServerBinarySize)}');
      }
      final sc = File('$outputDir/server/.quiver-config.json');
      if (!sc.existsSync()) {
        errors.add('server/.quiver-config.json is missing');
      }
    }

    final staticDir = Directory('$outputDir/static');
    if (staticDir.existsSync()) {
      var count = 0;
      await for (final e in staticDir.list(recursive: true)) {
        if (e is File) {
          count++;
          if (e.lengthSync() > maxFileSize) {
            errors.add('${e.path} exceeds ${_fmt(maxFileSize)}');
          }
        }
      }
      if (count == 0) errors.add('static/ is empty');
      if (count > maxStaticFileCount) {
        errors.add('Too many static files: $count');
      }
    }

    if (!serverDir.existsSync() && !staticDir.existsSync()) {
      errors.add('Must contain at least server/ or static/');
    }

    var total = 0;
    await for (final e in Directory(outputDir).list(recursive: true)) {
      if (e is File) total += e.lengthSync();
    }
    if (total > maxTotalSize) {
      errors.add('Total output exceeds ${_fmt(maxTotalSize)}');
    }

    return errors;
  }

  static Future<void> validateOrThrow(String outputDir) async {
    final errors = await validate(outputDir);
    if (errors.isNotEmpty) throw ValidationException(errors);
  }

  static String _fmt(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
