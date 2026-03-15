import 'dart:io';
import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class ServerpodDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    // TODO(mastersam07): This whole block should be revisited

    final hasServerpod = PubspecUtils.hasDependency(pubspec, 'serverpod');
    final hasConfigDir = Directory('$projectRoot/config').existsSync();

    if (hasServerpod && hasConfigDir) {
      return DetectionResult(
        detected: true,
        confidence: 0.95,
        reason: 'Found serverpod dependency and config/ directory',
        version: PubspecUtils.getDependencyVersion(pubspec, 'serverpod'),
      );
    }
    if (hasServerpod) {
      return DetectionResult(
        detected: true,
        confidence: 0.8,
        reason: 'Found serverpod dependency',
        version: PubspecUtils.getDependencyVersion(pubspec, 'serverpod'),
      );
    }
    return const DetectionResult.notDetected();
  }
}
