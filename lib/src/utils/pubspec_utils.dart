import 'dart:io';
import 'package:yaml/yaml.dart';
import '../core/exceptions.dart';

class PubspecUtils {
  static YamlMap readPubspec(String projectRoot) {
    final file = File('$projectRoot/pubspec.yaml');
    if (!file.existsSync()) {
      throw const PubspecException(
        'No pubspec.yaml found. Is this a Dart project?',
      );
    }
    final yaml = loadYaml(file.readAsStringSync());
    if (yaml is! YamlMap) {
      throw const PubspecException('pubspec.yaml is malformed');
    }
    return yaml;
  }

  static bool hasDependency(YamlMap pubspec, String packageName) {
    final deps = pubspec['dependencies'] as YamlMap?;
    final devDeps = pubspec['dev_dependencies'] as YamlMap?;
    return (deps?.containsKey(packageName) ?? false) ||
        (devDeps?.containsKey(packageName) ?? false);
  }

  static String? getDependencyVersion(YamlMap pubspec, String packageName) {
    final deps = pubspec['dependencies'] as YamlMap?;
    final dep = deps?[packageName];
    if (dep is String) return dep;
    if (dep is YamlMap) return dep['version']?.toString();
    return null;
  }

  static String? getProjectName(YamlMap pubspec) => pubspec['name']?.toString();

  static String? getDartSdkConstraint(YamlMap pubspec) {
    final env = pubspec['environment'] as YamlMap?;
    return env?['sdk']?.toString();
  }
}
