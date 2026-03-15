import 'dart:io';

import 'adapter.dart';
import 'build_config.dart';
import 'detector.dart';
import 'exceptions.dart';
import '../adapters/shelf_adapter.dart';
import '../adapters/dart_frog_adapter.dart';
import '../adapters/jaspr_adapter.dart';
import '../adapters/dart_adapter.dart';

/// Registry of all available framework adapters.
class AdapterRegistry {
  final List<QuiverAdapter> _adapters;

  const AdapterRegistry(this._adapters);

  /// Create a registry with all built-in adapters.
  factory AdapterRegistry.defaults() => AdapterRegistry([
    DartFrogAdapter(),
    // TODO(mastersam07): This should be revisited
    // ServerpodAdapter(),
    // ConduitAdapter(),
    JasprAdapter(),
    // TODO(mastersam07): This should be revisited
    // SerinusAdapter(),
    ShelfAdapter(),
    DartAdapter(), // Catch-all — must be last by confidence, not order
  ]);

  List<String> get adapterNames => _adapters.map((a) => a.name).toList();

  /// Resolve the best adapter for a project.
  ///
  /// 1. Check `quiver.yaml` for explicit framework override
  /// 2. Run all detectors, pick highest confidence
  Future<ResolvedAdapter> resolve(String projectRoot) async {
    // 1. Check for explicit override
    final config = BuildConfig.load(projectRoot);
    if (config?.framework case final framework?) {
      final adapter = _findByName(framework);
      if (adapter != null) {
        return ResolvedAdapter(
          adapter: adapter,
          result: const DetectionResult(
            detected: true,
            confidence: 1.0,
            reason: 'Specified in quiver.yaml',
          ),
        );
      }
      stderr.writeln(
        'Warning: quiver.yaml specifies "$framework" '
        'but no adapter with that name exists. '
        'Available: ${adapterNames.join(", ")}',
      );
    }

    // 2. Run all detectors
    final results = <QuiverAdapter, DetectionResult>{};
    for (final adapter in _adapters) {
      final result = await adapter.detector.detect(projectRoot);
      if (result.detected) results[adapter] = result;
    }

    if (results.isEmpty) throw const FrameworkNotDetectedException();

    // 3. Highest confidence wins
    final entries = results.entries.toList()
      ..sort((a, b) => b.value.confidence.compareTo(a.value.confidence));

    return ResolvedAdapter(
      adapter: entries.first.key,
      result: entries.first.value,
    );
  }

  QuiverAdapter? _findByName(String name) {
    final lower = name.toLowerCase();
    for (final adapter in _adapters) {
      if (adapter.name.toLowerCase() == lower) return adapter;
    }
    return null;
  }
}

class ResolvedAdapter {
  final QuiverAdapter adapter;
  final DetectionResult result;

  const ResolvedAdapter({required this.adapter, required this.result});

  @override
  String toString() =>
      '${adapter.displayName} '
      '(confidence: ${result.confidence}, reason: ${result.reason})';
}
