/// Base exception for all Quiver build errors.
class BuildException implements Exception {
  final String message;
  final String? hint;
  const BuildException(this.message, {this.hint});

  @override
  String toString() {
    final buffer = StringBuffer('BuildException: $message');
    if (hint case final hint?) buffer.write('\nHint: $hint');
    return buffer.toString();
  }
}

class FrameworkNotDetectedException extends BuildException {
  const FrameworkNotDetectedException()
    : super(
        'Could not detect a Dart framework in this project',
        hint:
            'Ensure pubspec.yaml has a supported framework dependency '
            'or specify one in quiver.yaml',
      );
}

class MissingDependencyException extends BuildException {
  final String dependency;
  MissingDependencyException(this.dependency)
    : super(
        'Missing required dependency: $dependency',
        hint: 'Run "dart pub add $dependency"',
      );
}

class CompilationException extends BuildException {
  final int exitCode;
  final String stderr;
  CompilationException({required this.exitCode, required this.stderr})
    : super(
        'Dart compilation failed (exit code $exitCode)',
        hint: stderr.isNotEmpty ? stderr.split('\n').first : null,
      );
}

class ValidationException extends BuildException {
  final List<String> errors;
  ValidationException(this.errors)
    : super(
        'Build output validation failed:\n${errors.map((e) => '  - $e').join('\n')}',
      );
}

class PubspecException extends BuildException {
  const PubspecException(super.message);
}
