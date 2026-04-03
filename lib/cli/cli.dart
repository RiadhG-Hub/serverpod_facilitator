import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../diff/diff_engine.dart';
import '../generator/admin_generator.dart';
import '../generator/auth_generator.dart';
import '../generator/client_generator.dart';
import '../mapper/mapper.dart';
import '../migration/migration_engine.dart';
import '../models/schema.dart';
import '../parser/parser.dart';
import '../validator/validator.dart';

class FacilitatorCli {
  final _parser = SchemaParser();
  final _mapper = YamlMapper();
  final _diffEngine = DiffEngine();
  final _validator = SchemaValidator();
  final _migrationEngine = MigrationEngine();
  final _authGenerator = AuthGenerator();
  final _adminGenerator = AdminGenerator();
  final _clientGenerator = ClientGenerator();

  Future<void> run(List<String> args) async {
    final argParser = ArgParser()
      ..addFlag('dry-run',
          negatable: false, help: 'Show changes without applying them.')
      ..addFlag('apply', negatable: false, help: 'Apply changes to files.')
      ..addOption('file', help: 'Process a specific file.')
      ..addCommand('create')
      ..addCommand('ai')
      ..addCommand('generate')
      ..addCommand('diff')
      ..addCommand('migration')
      ..addCommand('client')
      ..addCommand('admin')
      ..addCommand('auth')
      ..addCommand('watch')
      ..addCommand('explain')
      ..addCommand('impact')
      ..addCommand('validate');

    final results = argParser.parse(args);
    final command = results.command?.name;

    if (command == null) {
      print('Usage: facilitator <command> [options]');
      print(argParser.usage);
      return;
    }

    final filePath = results['file'] as String?;
    final filesToProcess = <File>[];

    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        filesToProcess.add(file);
      } else {
        print('Error: File $filePath not found.');
        return;
      }
    } else {
      final dir = Directory('lib/models');
      if (await dir.exists()) {
        await for (final file in dir.list(recursive: true)) {
          if (file is File && file.path.endsWith('.dart')) {
            filesToProcess.add(file);
          }
        }
      }
    }

    if (filesToProcess.isEmpty) {
      print('No Dart files found to process.');
      return;
    }

    final newModels = <ModelDefinition>[];
    for (final file in filesToProcess) {
      final content = await file.readAsString();
      newModels.addAll(_parser.parseFile(content));
    }

    switch (command) {
      case 'create':
        await _handleCreate(results.command!);
        break;
      case 'ai':
        await _handleAi(results.command!);
        break;
      case 'validate':
        _handleValidate(newModels);
        break;
      case 'diff':
        await _handleDiff(newModels);
        break;
      case 'generate':
        await _handleGenerate(newModels,
            dryRun: results['dry-run'], apply: results['apply']);
        break;
      case 'migration':
        await _handleMigration(newModels, results.command!);
        break;
      case 'auth':
        await _handleAuth(newModels, results.command!);
        break;
      case 'admin':
        await _handleAdmin(newModels, results.command!);
        break;
      case 'client':
        await _handleClient(newModels, results.command!);
        break;
      case 'watch':
        await _handleWatch(newModels);
        break;
      case 'explain':
        _handleExplain(newModels);
        break;
      case 'impact':
        _handleImpact(newModels);
        break;
    }
  }

  Future<void> _handleAi(ArgResults command) async {
    final prompt = command.arguments.isNotEmpty
        ? command.arguments.first
        : 'social media app';
    print('🤖 AI: Generating backend for: $prompt...');

    // AI Mock Logic: Depending on prompt, create more models
    if (prompt.contains('social')) {
      final postModel = File('lib/models/post.dart');
      await postModel.writeAsString('''
import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class Post {
  @PgPrimaryKey()
  int? id;
  
  @PgText()
  String content;
  
  @PgTimestamp()
  DateTime postedAt;
  
  @PgForeignKey('user', 'id')
  int userId;

  Post({
    this.id,
    required this.content,
    required this.postedAt,
    required this.userId,
  });
}
''');
      print('✅ AI generated Model: lib/models/post.dart');
    }
    print('✅ AI backend generation complete.');
  }

  Future<void> _handleCreate(ArgResults command) async {
    final projectName =
        command.arguments.isNotEmpty ? command.arguments.first : 'my_app';
    print('🚀 Creating project: $projectName...');

    final projectDir = Directory(projectName);
    if (await projectDir.exists()) {
      print('Error: Directory $projectName already exists.');
      return;
    }

    await projectDir.create();

    // Create basic structure
    await Directory(p.join(projectName, 'lib/models')).create(recursive: true);
    await Directory(p.join(projectName, 'lib/endpoints'))
        .create(recursive: true);
    await Directory(p.join(projectName, '.generated')).create(recursive: true);
    await Directory(p.join(projectName, 'docker')).create(recursive: true);

    // Create a sample model
    final userModel = File(p.join(projectName, 'lib/models/user.dart'));
    await userModel.writeAsString('''
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
  DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });
}
''');

    // Create pubspec.yaml
    final pubspec = File(p.join(projectName, 'pubspec.yaml'));
    await pubspec.writeAsString('''
name: $projectName
description: A new Serverpod project created with Facilitator.
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  serverpod: ^1.2.0
  serverpod_facilitator:
    path: ../ # Prototype assumption

dev_dependencies:
  serverpod_cli: ^1.2.0
''');

    // Create Dockerfile
    final dockerfile = File(p.join(projectName, 'docker/Dockerfile'));
    await dockerfile.writeAsString('''
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/main

FROM debian:bookworm-slim
COPY --from=build /app/bin/main /app/bin/main
CMD ["/app/bin/main"]
''');

    print('✅ Project $projectName created successfully!');
    print('👉 Next steps:');
    print('   cd $projectName');
    print('   facilitator generate');
  }

  Future<void> _handleMigration(
      List<ModelDefinition> models, ArgResults command) async {
    print('🧬 Generating migrations...');
    final oldModels = await _loadPreviousModels();
    final diff = _diffEngine.diff(oldModels, models);

    if (!diff.hasChanges) {
      print('No changes detected. No migration needed.');
      return;
    }

    final sql = _migrationEngine.generateSql(diff, oldModels, models);
    print('\n--- Generated SQL ---\n');
    print(sql);

    final migrationDir = Directory('migrations');
    if (!await migrationDir.exists()) {
      await migrationDir.create();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join('migrations', '${timestamp}_migration.sql');
    await File(filePath).writeAsString(sql);

    print('✅ Migration generated: $filePath');
  }

  Future<void> _handleAuth(
      List<ModelDefinition> models, ArgResults command) async {
    final projectPath = '.';
    await _authGenerator.generate(models, projectPath);
  }

  Future<void> _handleAdmin(
      List<ModelDefinition> models, ArgResults command) async {
    final projectPath = '.';
    await _adminGenerator.generate(models, projectPath);
  }

  Future<void> _handleClient(
      List<ModelDefinition> models, ArgResults command) async {
    final projectPath = '.';
    await _clientGenerator.generate(models, projectPath);
  }

  Future<void> _handleWatch(List<ModelDefinition> models) async {
    print('🔁 Watch mode started. Press Ctrl+C to stop.');
    // Implementation placeholder
  }

  void _handleExplain(List<ModelDefinition> models) {
    print('🔎 Project Explanation:');
    for (final model in models) {
      print('Model ${model.name} has ${model.fields.length} fields.');
    }
  }

  void _handleImpact(List<ModelDefinition> models) {
    print('🔎 Impact Analysis:');
    print('Generating these changes will affect the following tables:');
    for (final model in models) {
      print('  - ${_toSnakeCase(model.name)}');
    }
  }

  void _handleValidate(List<ModelDefinition> models) {
    final result = _validator.validate(models);
    if (result.isValid) {
      print('✅ Schema is valid.');
    } else {
      print('❌ Schema validation failed:');
      for (final error in result.errors) {
        print('  - $error');
      }
    }
  }

  Future<void> _handleDiff(List<ModelDefinition> newModels) async {
    final oldModels = await _loadPreviousModels();
    final diff = _diffEngine.diff(oldModels, newModels);
    _printDiff(diff);
  }

  Future<void> _handleGenerate(List<ModelDefinition> models,
      {bool dryRun = false, bool apply = false}) async {
    final validation = _validator.validate(models);
    if (!validation.isValid) {
      _handleValidate(models);
      return;
    }

    final oldModels = await _loadPreviousModels();
    final diff = _diffEngine.diff(oldModels, models);

    if (!diff.hasChanges) {
      print('No changes detected. Output is up to date.');
      return;
    }

    _printDiff(diff);

    if (dryRun) {
      print('\nDry-run mode: No files written.');
      return;
    }

    if (!apply) {
      stdout.write('\nDo you want to apply these changes? (y/N): ');
      final input = stdin.readLineSync();
      if (input?.toLowerCase() != 'y') {
        print('Aborted.');
        return;
      }
    }

    await _writeGeneratedFiles(models);
    print('✅ Files generated successfully in .generated/');
  }

  void _printDiff(SchemaDiff diff) {
    if (!diff.hasChanges) {
      print('No changes.');
      return;
    }

    for (final model in diff.addedModels) {
      print('+ Model: $model');
    }
    for (final model in diff.removedModels) {
      print('- Model: $model');
    }
    diff.fieldDiffs.forEach((model, fields) {
      print('~ Model: $model');
      for (final field in fields.addedFields) {
        print('  + Field: $field');
      }
      for (final field in fields.removedFields) {
        print('  - Field: $field');
      }
      fields.modifiedFields.forEach((field, change) {
        print('  ~ Field: $field (${change.oldType} -> ${change.newType})');
      });
    });
  }

  Future<List<ModelDefinition>> _loadPreviousModels() async {
    final dir = Directory('.generated');
    if (!await dir.exists()) return [];

    final models = <ModelDefinition>[];
    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.spyaml.yaml')) {
        final content = await file.readAsString();
        models.add(_parseYamlToModel(content));
      }
    }
    return models;
  }

  ModelDefinition _parseYamlToModel(String yaml) {
    // Basic parser for our generated YAML
    final lines = yaml.split('\n');
    String name = '';
    final fields = <FieldDefinition>[];

    bool inFields = false;
    for (var line in lines) {
      if (line.startsWith('class: ')) {
        name = line.substring(7).trim();
      } else if (line.startsWith('fields:')) {
        inFields = true;
      } else if (inFields && line.startsWith('  ')) {
        if (line.startsWith('    '))
          continue; // Skip indented properties for now
        final parts = line.trim().split(':');
        if (parts.length >= 2) {
          final fieldName = parts[0].trim();
          final typePart = parts[1].trim();
          final isNullable = typePart.endsWith('?');
          final baseType = isNullable
              ? typePart.substring(0, typePart.length - 1)
              : typePart;

          fields.add(FieldDefinition(
            name: fieldName,
            dartType: baseType.split(',').first.trim(),
            isNullable: isNullable,
          ));
        }
      } else if (line.trim().isEmpty) {
        continue;
      } else {
        inFields = false;
      }
    }

    return ModelDefinition(name: name, fields: fields);
  }

  Future<void> _writeGeneratedFiles(List<ModelDefinition> models) async {
    final dir = Directory('.generated');
    if (!await dir.exists()) {
      await dir.create();
    }

    for (final model in models) {
      final yaml = _mapper.mapToYaml(model);
      final file =
          File(p.join('.generated', '${_toSnakeCase(model.name)}.spyaml.yaml'));
      await file.writeAsString(yaml);
    }
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return (match.start == 0 ? '' : '_') + match.group(1)!.toLowerCase();
    }).toLowerCase();
  }
}
