import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

import '../diff/diff_engine.dart';
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

  Future<void> run(List<String> args) async {
    final argParser = ArgParser()
      ..addCommand(
          'generate',
          ArgParser()
            ..addFlag('dry-run', negatable: false, help: 'Show changes.')
            ..addFlag('apply',
                negatable: false,
                defaultsTo: true,
                help: 'Apply changes to files.')
            ..addFlag('serverpod',
                negatable: false,
                help: 'Run "serverpod generate" after facilitator.'))
      ..addCommand(
          'migration',
          ArgParser()
            ..addOption('name', help: 'Migration name.')
            ..addFlag('serverpod',
                negatable: false,
                help: 'Run "serverpod generate" after migration.'))
      ..addCommand(
          'watch',
          ArgParser()
            ..addOption('dir',
                abbr: 'd',
                defaultsTo: 'lib/models',
                help: 'Directory to watch.')
            ..addFlag('serverpod',
                negatable: false,
                help: 'Run "serverpod generate" on each change.'))
      ..addCommand('validate')
      ..addCommand('diff');

    if (args.isEmpty) {
      _printUsage(argParser);
      return;
    }

    late final ArgResults results;
    try {
      results = argParser.parse(args);
    } catch (e) {
      print('Error: $e');
      _printUsage(argParser);
      return;
    }

    final command = results.command?.name;

    if (command == null) {
      _printUsage(argParser);
      return;
    }

    switch (command) {
      case 'generate':
        await _handleGenerate(
          dryRun: results.command!['dry-run'],
          apply: results.command!['apply'],
          runServerpod: results.command!['serverpod'],
        );
        break;
      case 'watch':
        await _handleWatch(
          directory: results.command!['dir'],
          runServerpod: results.command!['serverpod'],
        );
        break;
      case 'migration':
        await _handleMigration(results.command!);
        break;
      case 'validate':
        await _handleValidate();
        break;
      case 'diff':
        await _handleDiff();
        break;
      default:
        _printUsage(argParser);
    }
  }

  void _printUsage(ArgParser argParser) {
    print('🚀 Serverpod Facilitator - Code-first schemas for Serverpod');
    print('\nUsage: serverpod_facilitator <command> [options]');
    print('\nAvailable commands:');
    for (final command in argParser.commands.keys.toList()..sort()) {
      print('  ${command.padRight(12)}');
    }
  }

  Future<List<ModelDefinition>> _processFiles({String? directory}) async {
    final filesToProcess = <File>[];
    final dirPath = directory ?? 'lib/models';
    final dir = Directory(dirPath);

    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          filesToProcess.add(file);
        }
      }
    }

    if (filesToProcess.isEmpty) {
      return [];
    }

    final models = <ModelDefinition>[];
    for (final file in filesToProcess) {
      final content = await file.readAsString();
      models.addAll(_parser.parseFile(content));
    }
    return models;
  }

  Future<void> _handleGenerate({
    bool dryRun = false,
    bool apply = true,
    bool runServerpod = false,
  }) async {
    final models = await _processFiles();
    if (models.isEmpty) {
      print('No models found in lib/models.');
      return;
    }

    final validation = _validator.validate(models);
    if (!validation.isValid) {
      print('❌ Schema validation failed:');
      for (final error in validation.errors) {
        print('  - $error');
      }
      return;
    }

    final oldModels = await _loadPreviousModels();
    final diff = _diffEngine.diff(oldModels, models);

    if (!diff.hasChanges) {
      print('No changes detected. Output is up to date.');
      if (runServerpod) await _runServerpodGenerate();
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
    print('✅ Serverpod YAML models updated in .generated/');

    if (runServerpod) {
      await _runServerpodGenerate();
    }
  }

  Future<void> _handleWatch({
    required String directory,
    bool runServerpod = false,
  }) async {
    print('🔁 Watch mode started on $directory. Press Ctrl+C to stop.');

    final watcher = DirectoryWatcher(p.absolute(directory));
    Timer? debounce;

    await for (final event in watcher.events) {
      if (event.path.endsWith('.dart')) {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 500), () async {
          print('File changed: ${event.path}. Regenerating...');
          await _handleGenerate(apply: true, runServerpod: runServerpod);
        });
      }
    }
  }

  Future<void> _handleMigration(ArgResults command) async {
    final models = await _processFiles();
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

    if (command['serverpod']) {
      await _runServerpodGenerate();
    }
  }

  Future<void> _handleValidate() async {
    final models = await _processFiles();
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

  Future<void> _handleDiff() async {
    final models = await _processFiles();
    final oldModels = await _loadPreviousModels();
    final diff = _diffEngine.diff(oldModels, models);
    _printDiff(diff);
  }

  Future<void> _runServerpodGenerate() async {
    print('🏃 Running "serverpod generate"...');
    final result = await Process.run('serverpod', ['generate']);
    if (result.exitCode == 0) {
      print(result.stdout);
      print('✅ Serverpod generation complete.');
    } else {
      print(result.stderr);
      print('❌ Serverpod generation failed.');
    }
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

  ModelDefinition _parseYamlToModel(String content) {
    final yaml = loadYaml(content) as YamlMap;
    final className = yaml['class'] as String;
    final fields = <FieldDefinition>[];

    final yamlFields = yaml['fields'] as YamlMap;
    yamlFields.forEach((key, value) {
      final typeStr = value.toString();
      final isNullable = typeStr.endsWith('?');
      final dartType = isNullable
          ? typeStr.substring(0, typeStr.indexOf('?'))
          : (typeStr.contains(',')
              ? typeStr.substring(0, typeStr.indexOf(','))
              : typeStr);

      fields.add(FieldDefinition(
        name: key as String,
        dartType: dartType.trim(),
        isNullable: isNullable,
      ));
    });

    return ModelDefinition(name: className, fields: fields);
  }

  Future<void> _writeGeneratedFiles(List<ModelDefinition> models) async {
    final dir = Directory('.generated');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Clean old generated files
    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.spyaml.yaml')) {
        await file.delete();
      }
    }

    for (final model in models) {
      final yaml = _mapper.mapToYaml(model);
      final fileName = '${_toSnakeCase(model.name)}.spyaml.yaml';
      await File(p.join(dir.path, fileName)).writeAsString(yaml);
    }
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return (match.start == 0 ? '' : '_') + match.group(1)!.toLowerCase();
    }).toLowerCase();
  }
}
