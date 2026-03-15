import 'dart:io';
import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class DartFrogDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    final hasDartFrog = PubspecUtils.hasDependency(pubspec, 'dart_frog');
    final hasRoutesDir = Directory('$projectRoot/routes').existsSync();

    if (hasDartFrog && hasRoutesDir) {
      return DetectionResult(
        detected: true,
        confidence: 0.95,
        reason: 'Found dart_frog dependency and routes/ directory',
        version: PubspecUtils.getDependencyVersion(pubspec, 'dart_frog'),
      );
    }
    if (hasDartFrog) {
      return DetectionResult(
        detected: true,
        confidence: 0.7,
        reason: 'Found dart_frog dependency but no routes/ directory',
        version: PubspecUtils.getDependencyVersion(pubspec, 'dart_frog'),
      );
    }
    return const DetectionResult.notDetected();
  }
}
