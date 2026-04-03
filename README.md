# 🚀 Serverpod Facilitator

**The ultimate developer platform for Serverpod.**

`serverpod_facilitator` transforms Serverpod into a top-tier backend framework competitor to Node.js ecosystems and Firebase. It provides a code-first, zero-magic experience with Prisma-level schema management and Firebase-level speed.

## 🎯 Objective

- **Firebase-level speed** ⚡: Bootstrap and deploy in minutes.
- **Prisma-level schema & migrations** 🧬: Type-safe, declarative database management.
- **Node.js-level extensibility** 🔌: Powerful plugin system.
- **Flutter-first full-stack experience** 📱: Seamless integration with Flutter.

---

## 🏗 Core Modules

- **CLI**: Unified command-line interface.
- **Parser**: AST-based Dart parser for extracting models and annotations.
- **Mapper**: Deterministic Dart → Serverpod YAML mapper.
- **Diff Engine**: Prisma-like detection of schema changes.
- **Migration Engine**: Automatic SQL migration generator.
- **Generators**: Specialized generators for Auth, Admin Panels, and Clients.
- **AI Tools**: Natural language backend generation.

---

## ⚡ Quick Start

### 1. Installation

Add `serverpod_facilitator` to your project's `pubspec.yaml`:

```yaml
dependencies:
  serverpod_facilitator: ^1.0.0
```

### 2. Create a New Project

Bootstrap a complete Serverpod + Flutter project in under 1 minute:

```bash
dart bin/facilitator.dart create my_awesome_app
```

### 3. Define Your Models

Create Dart classes in `lib/models/` using our PostgreSQL-aware annotations:

```dart
import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class User {
  @PgPrimaryKey()
  int? id;
  
  @PgVarchar(255)
  @PgUnique()
  String email;
  
  @PgText()
  String name;
  
  @PgTimestamp()
  @PgDefault('now()')
  DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });
}
```

### 4. Generate Schema & Migrations

```bash
# Generate Serverpod YAML files
dart bin/facilitator.dart generate --apply

# Generate SQL migrations
dart bin/facilitator.dart migration
```

---

## 🏷 Available Annotations

| Annotation | Description |
|------------|-------------|
| `@ServerpodModel({customSql})` | Marks a class as a Serverpod model. |
| `@PgVarchar(length)` | PostgreSQL `VARCHAR(n)` type. |
| `@PgText()` | PostgreSQL `TEXT` type. |
| `@PgInt()` | PostgreSQL `INTEGER` type. |
| `@PgBigInt()` | PostgreSQL `BIGINT` type. |
| `@PgBoolean()` | PostgreSQL `BOOLEAN` type. |
| `@PgTimestamp()` | PostgreSQL `TIMESTAMP` type. |
| `@PgTimestamptz()` | PostgreSQL `TIMESTAMPTZ` type. |
| `@PgJson()` / `@PgJsonb()` | PostgreSQL `JSON` / `JSONB` types. |
| `@PgUuid()` | PostgreSQL `UUID` type. |
| `@PgNumeric(p, s)` | PostgreSQL `NUMERIC(precision, scale)`. |
| `@PgPrimaryKey()` | Marks a field as the Primary Key. |
| `@PgUnique()` | Adds a unique constraint. |
| `@PgIndex({name})` | Creates a database index. |
| `@PgForeignKey(table, col)`| Defines a foreign key relationship. |
| `@PgDefault(value)` | Sets a default database value. |
| `@PgCustomSql(sql)` | Custom SQL override for a specific field. |
| `@Realtime()` | Enables realtime subscriptions for the model. |

---

## 🖥 CLI Commands

### Project Initialization
- `create <name>`: Bootstraps a new project with Serverpod, Flutter, and Docker.
- `ai "<prompt>"`: Generates models and endpoints from natural language.

### Schema Management
- `validate`: Checks your Dart models for errors or inconsistencies.
- `diff`: Shows a preview of changes between Dart code and generated YAML.
- `generate`: Translates Dart models into Serverpod `.spyaml.yaml` files.
  - `--dry-run`: Preview changes without writing files.
  - `--apply`: Skip the confirmation prompt.
- `migration`: Generates versioned SQL migration files based on schema changes.

### Code Generation
- `auth`: Generates a complete Authentication system (JWT, Email/Password).
- `admin`: Generates a Flutter Web Admin Dashboard for CRUD operations.
- `client`: Generates a typed Flutter API client for your models.

### Developer Tools
- `watch`: Automatically regenerates schema on file changes.
- `explain`: Describes your backend architecture in human language.
- `impact`: Analyzes the impact of schema changes on the database.

---

## 🔌 Plugin System

Extend the facilitator by implementing `FacilitatorPlugin`:

```dart
abstract class FacilitatorPlugin {
  void register();
}
```

Plugins can add custom CLI commands, new annotations, or specialized generators.

---

## 🧪 Testing

Run the test suite to ensure everything is working correctly:

```bash
dart test
```

## ⚠️ Robustness & Safety

1. **Zero Magic**: No hidden logic; everything is explicit and inspectable.
2. **Deterministic**: Same input always produces the same output.
3. **Dry-Run First**: Always supports `--dry-run` and diff previews.
4. **Non-Destructive**: Never overwrites user code; generated code lives in `.generated/`.

---

Built with ❤️ for the Serverpod & Flutter community.
