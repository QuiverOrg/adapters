# Quiver Adapter

**Framework detection and build system for the Quiver deployment platform.**

Quiver Adapter automatically detects which Dart framework a project uses, builds it into the standardized Quiver Build Output Spec, and validates the output for deployment.

## Supported Frameworks

- Dart Frog
- Serverpod
- Conduit
- Jaspr (SSR & SSG)
- Serinus
- Shelf
- Generic Dart (catch-all)

## Usage

```dart
import 'package:quiver_adapter/quiver_adapter.dart';

final registry = AdapterRegistry.defaults();
final resolved = await registry.resolve('/path/to/project');
print('Detected: ${resolved.adapter.displayName}');
```

## Development

```bash
git clone https://github.com/quiverorg/adapters.git
cd adapters
dart pub get
```

## License

MIT
