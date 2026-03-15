import 'dart:io';
import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class ShelfDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    final hasShelf = PubspecUtils.hasDependency(pubspec, 'shelf');
    final hasEntrypoint =
        File('$projectRoot/bin/server.dart').existsSync() ||
        File('$projectRoot/bin/main.dart').existsSync();

    if (hasShelf && hasEntrypoint) {
      return DetectionResult(
        detected: true,
        confidence: 0.85,
        reason: 'Found shelf dependency and server entrypoint',
        version: PubspecUtils.getDependencyVersion(pubspec, 'shelf'),
      );
    }
    if (hasShelf) {
      return DetectionResult(
        detected: true,
        confidence: 0.5,
        reason: 'Found shelf dependency but no entrypoint in bin/',
        version: PubspecUtils.getDependencyVersion(pubspec, 'shelf'),
      );
    }
    return const DetectionResult.notDetected();
  }
}
