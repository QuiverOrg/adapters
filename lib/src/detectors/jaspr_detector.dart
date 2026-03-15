import 'package:yaml/yaml.dart';

import '../core/detector.dart';
import '../core/exceptions.dart';
import '../utils/pubspec_utils.dart';

class JasprDetector extends FrameworkDetector {
  @override
  Future<DetectionResult> detect(String projectRoot) async {
    final YamlMap pubspec;
    try {
      pubspec = PubspecUtils.readPubspec(projectRoot);
    } on PubspecException {
      return const DetectionResult.notDetected();
    }

    final hasJaspr = PubspecUtils.hasDependency(pubspec, 'jaspr');
    final hasBuilder = PubspecUtils.hasDependency(pubspec, 'jaspr_builder');

    if (hasJaspr) {
      return DetectionResult(
        detected: true,
        confidence: hasBuilder ? 0.9 : 0.8,
        reason: hasBuilder
            ? 'Found jaspr and jaspr_builder dependencies'
            : 'Found jaspr dependency',
        version: PubspecUtils.getDependencyVersion(pubspec, 'jaspr'),
      );
    }
    return const DetectionResult.notDetected();
  }
}
