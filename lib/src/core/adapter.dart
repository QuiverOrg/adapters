import 'dart:async';

import 'build_context.dart';
import 'build_output.dart';
import 'detector.dart';

/// The contract that all Quiver framework adapters must implement.
abstract class QuiverAdapter {
  /// Unique identifier (e.g., `shelf`, `dart_frog`).
  String get name;

  /// Human-readable name (e.g., "Shelf", "Dart Frog").
  String get displayName;

  /// The detector that determines if this adapter handles a project.
  FrameworkDetector get detector;

  /// Build the project into the Quiver Build Output Spec.
  ///
  /// Must produce valid output in [BuildContext.outputDir].
  /// Throws [BuildException] on failure.
  Future<BuildOutput> build(BuildContext context);

  /// Optional cleanup after a build.
  Future<void> cleanup(BuildContext context) async {}
}
