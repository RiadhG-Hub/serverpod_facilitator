

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import '../parser/parser.dart';
import '../mapper/mapper.dart';
import '../diff/diff_engine.dart';
import '../validator/validator.dart';
import '../models/schema.dart';

class FacilitatorCli {
  final _parser = SchemaParser();
  final _mapper = YamlMapper();
  final _diffEngine = DiffEngine();
  final _validator = SchemaValidator();

  Future<void> run(List<String> args) async {
    final argParser = ArgParser()
      ..addFlag('dry-run', negatable: false, help: 'Show changes without applying them.')
      ..addFlag('apply', negatable: false, help: 'Apply changes to files.')
      ..addOption('file', help: 'Process a specific file.')
      ..addCommand('generate')
      ..addCommand('diff')
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
      case 'validate':
        _handleValidate(newModels);
        break;
      case 'diff':
        await _handleDiff(newModels);
        break;
      case 'generate':
        await _handleGenerate(newModels, dryRun: results['dry-run'], apply: results['apply']);
        break;
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

  Future<void> _handleGenerate(List<ModelDefinition> models, {bool dryRun = false, bool apply = false}) async {
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
    // Prototype: return empty list for now.
    return [];
  }

  Future<void> _writeGeneratedFiles(List<ModelDefinition> models) async {
    final dir = Directory('.generated');
    if (!await dir.exists()) {
      await dir.create();
    }

    for (final model in models) {
      final yaml = _mapper.mapToYaml(model);
      final file = File(p.join('.generated', '${_toSnakeCase(model.name)}.spyaml.yaml'));
      await file.writeAsString(yaml);
    }
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return (match.start == 0 ? '' : '_') + match.group(1)!.toLowerCase();
    }).toLowerCase();
  }
}
