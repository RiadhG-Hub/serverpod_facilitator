# 🚀 Serverpod Facilitator

**The Dart-First bridge for Serverpod.**

`serverpod_facilitator` allows you to define your Serverpod models directly in Dart. No more manual YAML editing. Stay in your favorite language, use full IDE support, and let Facilitator handle the rest.

## 🎯 The Core Feature: Dart-to-YAML

The most powerful feature for Serverpod developers: **Code-first schemas**.
Instead of writing `.yaml` files, you write annotated Dart classes. Facilitator parses them and generates the `.spyaml.yaml` files that Serverpod expects.

### Why it's great:
- **Type Safety**: Use Dart types and get compile-time checks.
- **IDE Power**: Refactor names, find usages, and use autocomplete.
- **Stay in the Flow**: No context switching between Dart and YAML.

---

## ⚡ Quick Start

### 1. Installation

Add `serverpod_facilitator` to your `pubspec.yaml`:

```yaml
dependencies:
  serverpod_facilitator: ^1.0.2
```

### 2. Define Your Models in Dart

Create Dart classes in `lib/models/`:

```dart
import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class User {
  int? id;
  
  @PgVarchar(255)
  @PgUnique()
  String email;
  
  String name;
  
  @Relation()
  List<Post>? posts;

  User({this.id, required this.email, required this.name, this.posts});
}
```

### 3. Generate & Watch

```bash
# Generate Serverpod YAML files once
serverpod_facilitator generate

# Watch for changes and regenerate automatically (The best for Devs!)
serverpod_facilitator watch --serverpod
```

The `--serverpod` flag tells Facilitator to automatically run `serverpod generate` whenever your Dart models change.

---

## 🖥 CLI Commands

- `generate`: Translates Dart models into Serverpod `.spyaml.yaml` files.
  - `--serverpod`: Automatically runs `serverpod generate` after.
- `watch`: Real-time monitoring of your Dart models.
  - `--serverpod`: Triggers full Serverpod generation on every change.
- `migration`: Generates versioned SQL migration files.
- `validate`: Checks your Dart models for errors.
- `diff`: Preview changes before applying them.

---

## 🏷 Key Annotations

- `@ServerpodModel()`: Mark a class as a model.
- `@PgUnique()`, `@PgIndex()`: Database constraints.
- `@Relation()`, `@Parent()`: Define Serverpod relationships in Dart.
- `@PgVarchar()`, `@PgText()`, `@PgDefault()`: Fine-tune your DB schema.

---

## 🏗 How it works

1. **Parse**: Facilitator uses the Dart analyzer to read your classes and annotations.
2. **Map**: It converts Dart structures to Serverpod's YAML format.
3. **Sync**: It writes `.spyaml.yaml` files to your project.
4. **Trigger**: If requested, it calls Serverpod's own generator to finish the job.

Built with ❤️ for the Serverpod community.
