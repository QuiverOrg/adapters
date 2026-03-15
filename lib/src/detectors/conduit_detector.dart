import 'dart:io';
import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class ConduitDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    // TODO(mastersam07): This whole block should be revisited
    final hasConduit =
        PubspecUtils.hasDependency(pubspec, 'conduit') ||
        PubspecUtils.hasDependency(pubspec, 'conduit_core');
    final hasConfig =
        File('$projectRoot/config.yaml').existsSync() ||
        File('$projectRoot/config.src.yaml').existsSync();

    if (hasConduit && hasConfig) {
      return DetectionResult(
        detected: true,
        confidence: 0.9,
        reason: 'Found conduit dependency and config.yaml',
        version:
            PubspecUtils.getDependencyVersion(pubspec, 'conduit') ??
            PubspecUtils.getDependencyVersion(pubspec, 'conduit_core'),
      );
    }
    if (hasConduit) {
      return DetectionResult(
        detected: true,
        confidence: 0.75,
        reason: 'Found conduit dependency',
        version: PubspecUtils.getDependencyVersion(pubspec, 'conduit'),
      );
    }
    return const DetectionResult.notDetected();
  }
}
