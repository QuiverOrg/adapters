import 'dart:io';
import 'package:yaml/yaml.dart';

/// User-provided build configuration from `quiver.yaml`.
class BuildConfig {
  final String? framework;
  final String? buildCommand;
  final String? outputDirectory;
  final String? entrypoint;
  final List<String>? regions;
  final List<String>? env;

  const BuildConfig({
    this.framework,
    this.buildCommand,
    this.outputDirectory,
    this.entrypoint,
    this.regions,
    this.env,
  });

  static BuildConfig? load(String projectRoot) {
    final file = File('$projectRoot/quiver.yaml');
    if (!file.existsSync()) return null;
    final yaml = loadYaml(file.readAsStringSync()) as YamlMap?;
    if (yaml == null) return null;
    return BuildConfig(
      framework: yaml['framework'] as String?,
      buildCommand: yaml['buildCommand'] as String?,
      outputDirectory: yaml['outputDirectory'] as String?,
      entrypoint: yaml['entrypoint'] as String?,
      regions: (yaml['regions'] as YamlList?)?.cast<String>(),
      env: (yaml['env'] as YamlList?)?.cast<String>(),
    );
  }
}
