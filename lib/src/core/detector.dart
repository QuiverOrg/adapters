/// Determines whether an adapter can handle a given project.
abstract class FrameworkDetector {
  Future<DetectionResult> detect(String projectRoot);
}

/// Result of a framework detection check.
class DetectionResult {
  final bool detected;

  /// 0.0–1.0. Higher confidence wins when multiple adapters match.
  final double confidence;
  final String reason;
  final String? version;

  const DetectionResult({
    required this.detected,
    required this.confidence,
    required this.reason,
    this.version,
  });

  const DetectionResult.notDetected({String? reason})
    : detected = false,
      confidence = 0.0,
      reason = reason ?? 'Framework not detected',
      version = null;

  @override
  String toString() =>
      'DetectionResult(detected: $detected, confidence: $confidence, reason: $reason)';
}
