import 'dart:io';
import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class DartDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    try {
      PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected(reason: 'No pubspec.yaml');
    }

    // Find any .dart entrypoint in bin/
    String? entrypoint;
    for (final name in ['bin/server.dart', 'bin/main.dart']) {
      if (File('$projectRoot/$name').existsSync()) {
        entrypoint = name;
        break;
      }
    }
    if (entrypoint == null) {
      final binDir = Directory('$projectRoot/bin');
      if (binDir.existsSync()) {
        for (final entity in binDir.listSync()) {
          if (entity is File && entity.path.endsWith('.dart')) {
            entrypoint = 'bin/${entity.uri.pathSegments.last}';
            break;
          }
        }
      }
    }

    if (entrypoint != null) {
      return DetectionResult(
        detected: true,
        confidence: 0.3,
        reason: 'Found Dart project with entrypoint at $entrypoint',
      );
    }
    return const DetectionResult.notDetected(
      reason: 'No server entrypoint in bin/',
    );
  }
}
