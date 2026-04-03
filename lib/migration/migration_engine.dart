import '../diff/diff_engine.dart';
import '../models/schema.dart';

class MigrationEngine {
  String generateSql(SchemaDiff diff, List<ModelDefinition> oldSchema,
      List<ModelDefinition> newSchema) {
    final buffer = StringBuffer();
    final newMap = {for (var m in newSchema) m.name: m};

    // Added models
    for (final modelName in diff.addedModels) {
      final model = newMap[modelName]!;
      buffer.writeln('-- Create table ${_toSnakeCase(modelName)}');
      buffer.writeln('CREATE TABLE ${_toSnakeCase(modelName)} (');
      final columns = <String>[];
      for (final field in model.fields) {
        columns.add('  ${_toSnakeCase(field.name)} ${_getSqlType(field)}');
      }
      buffer.writeln(columns.join(',\n'));
      buffer.writeln(');');
      buffer.writeln('\n');
    }

    // Removed models
    for (final modelName in diff.removedModels) {
      buffer.writeln('-- Drop table ${_toSnakeCase(modelName)}');
      buffer.writeln('DROP TABLE ${_toSnakeCase(modelName)};\n');
    }

    // Field changes
    diff.fieldDiffs.forEach((modelName, fieldDiff) {
      final tableName = _toSnakeCase(modelName);
      final model = newMap[modelName]!;

      for (final fieldName in fieldDiff.addedFields) {
        final field = model.fields.firstWhere((f) => f.name == fieldName);
        buffer.writeln('-- Add column $fieldName to $tableName');
        buffer.writeln(
            'ALTER TABLE $tableName ADD COLUMN ${_toSnakeCase(fieldName)} ${_getSqlType(field)};');
      }

      for (final fieldName in fieldDiff.removedFields) {
        buffer.writeln('-- Drop column $fieldName from $tableName');
        buffer.writeln(
            'ALTER TABLE $tableName DROP COLUMN ${_toSnakeCase(fieldName)};');
      }

      fieldDiff.modifiedFields.forEach((fieldName, change) {
        final field = model.fields.firstWhere((f) => f.name == fieldName);
        buffer.writeln('-- Modify column $fieldName in $tableName');
        buffer.writeln(
            'ALTER TABLE $tableName ALTER COLUMN ${_toSnakeCase(fieldName)} TYPE ${_getSqlType(field, baseOnly: true)};');
        if (field.isNullable) {
          buffer.writeln(
              'ALTER TABLE $tableName ALTER COLUMN ${_toSnakeCase(fieldName)} DROP NOT NULL;');
        } else {
          buffer.writeln(
              'ALTER TABLE $tableName ALTER COLUMN ${_toSnakeCase(fieldName)} SET NOT NULL;');
        }
      });
      buffer.writeln();
    });

    return buffer.toString();
  }

  String _getSqlType(FieldDefinition field, {bool baseOnly = false}) {
    String type = 'TEXT';
    bool isPrimaryKey = false;

    for (final ann in field.annotations) {
      if (ann is VarcharAnnotation) type = 'VARCHAR(${ann.length})';
      if (ann is TextAnnotation) type = 'TEXT';
      if (ann is IntAnnotation) type = 'INTEGER';
      if (ann is BigIntAnnotation) type = 'BIGINT';
      if (ann is BooleanAnnotation) type = 'BOOLEAN';
      if (ann is JsonAnnotation) type = 'JSON';
      if (ann is JsonbAnnotation) type = 'JSONB';
      if (ann is UuidAnnotation) type = 'UUID';
      if (ann is NumericAnnotation)
        type = 'NUMERIC(${ann.precision}, ${ann.scale})';
      if (ann is TimestampAnnotation) type = 'TIMESTAMP';
      if (ann is TimestamptzAnnotation) type = 'TIMESTAMPTZ';

      if (ann is PrimaryKeyAnnotation) isPrimaryKey = true;
    }

    if (!baseOnly && isPrimaryKey) type += ' PRIMARY KEY';

    if (!baseOnly && !field.isNullable && !isPrimaryKey) {
      type += ' NOT NULL';
    }

    return type;
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return (match.start == 0 ? '' : '_') + match.group(1)!.toLowerCase();
    }).toLowerCase();
  }
}
