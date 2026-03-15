import 'dart:convert';
import 'dart:io';

class ServerConfig {
  final String runtime;
  final String entrypoint;
  final int memory;
  final int maxDuration;
  final List<String> envVarsInUse;

  const ServerConfig({
    this.runtime = 'dart-aot',
    this.entrypoint = 'main',
    this.memory = 256,
    this.maxDuration = 30,
    this.envVarsInUse = const [],
  });

  Map<String, dynamic> toJson() => {
    'runtime': runtime,
    'entrypoint': entrypoint,
    'memory': memory,
    'maxDuration': maxDuration,
    if (envVarsInUse.isNotEmpty) 'envVarsInUse': envVarsInUse,
  };

  Future<void> writeTo(String directory) async {
    final file = File('$directory/.quiver-config.json');
    await file.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
    );
  }
}
