

import 'package:test/test.dart';
import 'package:serverpod_facilitator/diff/diff_engine.dart';
import 'package:serverpod_facilitator/models/schema.dart';

void main() {
  final engine = DiffEngine();

  test('detect added model', () {
    final oldSchema = <ModelDefinition>[];
    final newSchema = [ModelDefinition(name: 'User', fields: [])];

    final diff = engine.diff(oldSchema, newSchema);
    expect(diff.addedModels, contains('User'));
    expect(diff.hasChanges, true);
  });

  test('detect added field', () {
    final oldSchema = [ModelDefinition(name: 'User', fields: [])];
    final newSchema = [
      ModelDefinition(name: 'User', fields: [
        FieldDefinition(name: 'name', dartType: 'String', isNullable: false)
      ])
    ];

    final diff = engine.diff(oldSchema, newSchema);
    expect(diff.fieldDiffs.containsKey('User'), true);
    expect(diff.fieldDiffs['User']!.addedFields, contains('name'));
    expect(diff.hasChanges, true);
  });

  test('detect modified field type', () {
    final oldSchema = [
      ModelDefinition(name: 'User', fields: [
        FieldDefinition(name: 'age', dartType: 'int', isNullable: false)
      ])
    ];
    final newSchema = [
      ModelDefinition(name: 'User', fields: [
        FieldDefinition(name: 'age', dartType: 'double', isNullable: false)
      ])
    ];

    final diff = engine.diff(oldSchema, newSchema);
    expect(diff.fieldDiffs['User']!.modifiedFields.containsKey('age'), true);
    expect(diff.fieldDiffs['User']!.modifiedFields['age']!.oldType, 'int');
    expect(diff.fieldDiffs['User']!.modifiedFields['age']!.newType, 'double');
  });
}
