import 'dart:io';
import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class SerinusDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    final hasSerinus = PubspecUtils.hasDependency(pubspec, 'serinus');
    if (!hasSerinus) return const DetectionResult.notDetected();

    final version = PubspecUtils.getDependencyVersion(pubspec, 'serinus');

    // Check if entrypoint imports serinus
    // TODO(mastersam07): This whole block should be revisited
    for (final path in ['bin/main.dart', 'bin/server.dart']) {
      final file = File('$projectRoot/$path');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.contains('package:serinus/') ||
            content.contains('SerinusApplication')) {
          return DetectionResult(
            detected: true,
            confidence: 0.88,
            reason:
                'Found serinus dependency and SerinusApplication entrypoint',
            version: version,
          );
        }
      }
    }

    return DetectionResult(
      detected: true,
      confidence: 0.7,
      reason: 'Found serinus dependency',
      version: version,
    );
  }
}
