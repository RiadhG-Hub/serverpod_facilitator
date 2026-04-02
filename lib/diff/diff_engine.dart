

import '../models/schema.dart';
import 'package:collection/collection.dart';

class SchemaDiff {
  final List<String> addedModels = [];
  final List<String> removedModels = [];
  final Map<String, FieldDiff> fieldDiffs = {};

  bool get hasChanges => addedModels.isNotEmpty || removedModels.isNotEmpty || fieldDiffs.isNotEmpty;
}

class FieldDiff {
  final List<String> addedFields = [];
  final List<String> removedFields = [];
  final Map<String, FieldChange> modifiedFields = {};

  bool get hasChanges => addedFields.isNotEmpty || removedFields.isNotEmpty || modifiedFields.isNotEmpty;
}

class FieldChange {
  final String oldType;
  final String newType;
  FieldChange(this.oldType, this.newType);
}

class DiffEngine {
  SchemaDiff diff(List<ModelDefinition> oldSchema, List<ModelDefinition> newSchema) {
    final diff = SchemaDiff();
    final oldMap = {for (var m in oldSchema) m.name: m};
    final newMap = {for (var m in newSchema) m.name: m};

    for (final name in newMap.keys) {
      if (!oldMap.containsKey(name)) {
        diff.addedModels.add(name);
      } else {
        final fieldDiff = _diffFields(oldMap[name]!, newMap[name]!);
        if (fieldDiff.hasChanges) {
          diff.fieldDiffs[name] = fieldDiff;
        }
      }
    }

    for (final name in oldMap.keys) {
      if (!newMap.containsKey(name)) {
        diff.removedModels.add(name);
      }
    }

    return diff;
  }

  FieldDiff _diffFields(ModelDefinition oldModel, ModelDefinition newModel) {
    final diff = FieldDiff();
    final oldFields = {for (var f in oldModel.fields) f.name: f};
    final newFields = {for (var f in newModel.fields) f.name: f};

    for (final name in newFields.keys) {
      if (!oldFields.containsKey(name)) {
        diff.addedFields.add(name);
      } else {
        final oldF = oldFields[name]!;
        final newF = newFields[name]!;
        if (oldF.dartType != newF.dartType || oldF.isNullable != newF.isNullable) {
          diff.modifiedFields[name] = FieldChange(
            '${oldF.dartType}${oldF.isNullable ? "?" : ""}',
            '${newF.dartType}${newF.isNullable ? "?" : ""}',
          );
        }
      }
    }

    for (final name in oldFields.keys) {
      if (!newFields.containsKey(name)) {
        diff.removedFields.add(name);
      }
    }

    return diff;
  }
}
