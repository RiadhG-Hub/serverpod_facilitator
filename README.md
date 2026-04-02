# Serverpod Facilitator

A code-first schema system for Serverpod.

## Features

- **Code-First**: Define your Serverpod models using Dart classes and annotations.
- **PostgreSQL Type Support**: Extensive support for PostgreSQL data types (Varchar, Text, BigInt, Jsonb, Uuid, Numeric, Timestamp, etc.).
- **Custom SQL**: Support for custom SQL requests (e.g., specialized indexes, views) directly in your model definitions.
- **Safe & Transparent**: Dry-run mode and confirmation before applying changes.
- **Diff Engine**: See what changed before applying.
- **AST Parser**: Reliable parsing of Dart source files.

## Usage

1. Define your models in `lib/models/`:

```dart
import '../annotations/annotations.dart';

@ServerpodModel(customSql: [
  'CREATE INDEX profile_bio_trgm_idx ON profile USING gin (bio gin_trgm_ops);',
])
class Profile {
  @PgVarchar(255)
  late String name;

  @PgUnique()
  @PgText()
  late String bio;

  @PgBigInt()
  late int points;

  @PgJsonb()
  late Map<String, dynamic> metadata;

  @PgDefault('now()')
  late DateTime createdAt;
}
```

2. Run the facilitator:

```bash
# Validate your schema
dart bin/facilitator.dart validate

# See the diff
dart bin/facilitator.dart diff

# Generate YAML files
dart bin/facilitator.dart generate --apply
```

## Available Annotations

- `@ServerpodModel({List<String>? customSql})`
- `@PgVarchar(length)`
- `@PgText()`
- `@PgUnique()`
- `@PgIndex({String? name})`
- `@PgDefault(value)`
- `@PgPrimaryKey()`
- `@PgForeignKey(table, column)`
- `@PgBigInt()`
- `@PgJson()`
- `@PgJsonb()`
- `@PgUuid()`
- `@PgNumeric(precision, scale)`
- `@PgTimestamp()`
- `@PgTimestamptz()`
- `@PgCustomSql(sql)` - Use for specific field database overrides

## Commands

- `validate`: Check schema for errors.
- `diff`: Show changes between current code and generated YAML.
- `generate`: Generate Serverpod YAML files.

## Options

- `--dry-run`: Show changes without writing files.
- `--apply`: Skip confirmation prompt.
- `--file=<path>`: Process a specific file.
