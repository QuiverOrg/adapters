/// Framework adapters for the Quiver deployment platform.
///
/// Provides framework detection, build pipeline, and output validation
/// for deploying Dart projects to Quiver.
///
/// ```dart
/// import 'package:quiver_adapter/quiver_adapter.dart';
///
/// final registry = AdapterRegistry.defaults();
/// final resolved = await registry.resolve('/path/to/project');
/// print('Detected: ${resolved.adapter.displayName}');
/// ```
library;

// Core
export 'src/core/adapter.dart';
export 'src/core/build_config.dart';
export 'src/core/build_context.dart';
export 'src/core/build_output.dart';
export 'src/core/detector.dart';
export 'src/core/exceptions.dart';
export 'src/core/registry.dart';
export 'src/core/validator.dart';

// Models
export 'src/models/framework_info.dart';
export 'src/models/route_config.dart';
export 'src/models/server_config.dart';

// Utils
export 'src/utils/process_utils.dart';
export 'src/utils/pubspec_utils.dart';

// Adapters
export 'src/adapters/shelf_adapter.dart';
export 'src/adapters/dart_frog_adapter.dart';
export 'src/adapters/serverpod_adapter.dart';
export 'src/adapters/conduit_adapter.dart';
export 'src/adapters/jaspr_adapter.dart';
export 'src/adapters/serinus_adapter.dart';
export 'src/adapters/dart_adapter.dart';

// Detectors
export 'src/detectors/shelf_detector.dart';
export 'src/detectors/dart_frog_detector.dart';
export 'src/detectors/serverpod_detector.dart';
export 'src/detectors/conduit_detector.dart';
export 'src/detectors/jaspr_detector.dart';
export 'src/detectors/serinus_detector.dart';
export 'src/detectors/dart_detector.dart';
