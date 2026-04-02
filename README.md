# Serverpod Facilitator

A code-first schema system for Serverpod.

## Features
- AST Parser for Dart files
- Annotation-based schema definition
- Automated Serverpod YAML generation
- Diff engine for schema changes
- Validation system

## Usage

1. Define your models in `lib/models/`:

```dart
import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class User {
  @PgVarchar(255)
  String name;

  @PgUnique()
  String email;

  @PgDefault('now()')
  DateTime createdAt;
}
```

2. Run the facilitator:

```bash
dart bin/facilitator.dart generate
```

## Commands
- `validate`: Check schema for errors.
- `diff`: Show changes between current code and generated YAML.
- `generate`: Generate Serverpod YAML files.

## Options
- `--dry-run`: Show changes without writing files.
- `--apply`: Skip confirmation prompt.
- `--file=<path>`: Process a specific file.
