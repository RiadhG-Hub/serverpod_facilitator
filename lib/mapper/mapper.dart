import '../models/schema.dart';

class YamlMapper {
  String mapToYaml(ModelDefinition model) {
    final buffer = StringBuffer();
    buffer.writeln('class: ${model.name}');
    buffer.writeln('table: ${_toSnakeCase(model.name)}');
    buffer.writeln('fields:');

    for (final field in model.fields) {
      buffer.writeln('  ${field.name}: ${_mapFieldType(field)}');
    }

    final indexes = _mapIndexes(model);
    if (indexes.isNotEmpty) {
      buffer.writeln('indexes:');
      for (final index in indexes) {
        buffer.writeln('  ${index.name}:');
        buffer.writeln('    fields: ${index.fields}');
        if (index.unique) {
          buffer.writeln('    unique: true');
        }
      }
    }

    return buffer.toString();
  }

  String _mapFieldType(FieldDefinition field) {
    String type = _getRawType(field);
    if (field.isNullable) {
      type += '?';
    }

    final annotations = <String>[];
    for (final ann in field.annotations) {
      if (ann is DefaultAnnotation) {
        annotations.add('default=${ann.value}');
      }
      // Serverpod YAML supports some database-specific types directly or via database:
    }

    if (annotations.isNotEmpty) {
      // This part depends on exact Serverpod YAML format for database overrides
      // For simplicity, we just return the type.
      // In a real implementation, we'd add 'database: ...'
    }

    return type;
  }

  String _getRawType(FieldDefinition field) {
    // Check for database overrides first
    for (final ann in field.annotations) {
      if (ann is VarcharAnnotation)
        return 'String, database=varchar(${ann.length})';
      if (ann is TextAnnotation) return 'String, database=text';
    }

    switch (field.dartType) {
      case 'String':
        return 'String';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'DateTime':
        return 'DateTime';
      case 'ByteData':
        return 'ByteData';
      default:
        return field.dartType;
    }
  }

  List<_IndexInfo> _mapIndexes(ModelDefinition model) {
    final indexes = <_IndexInfo>[];
    for (final field in model.fields) {
      for (final ann in field.annotations) {
        if (ann is UniqueAnnotation) {
          indexes.add(
            _IndexInfo(
              name:
                  '${_toSnakeCase(model.name)}_${_toSnakeCase(field.name)}_unique',
              fields: field.name,
              unique: true,
            ),
          );
        } else if (ann is IndexAnnotation) {
          indexes.add(
            _IndexInfo(
              name:
                  ann.name ??
                  '${_toSnakeCase(model.name)}_${_toSnakeCase(field.name)}_idx',
              fields: field.name,
              unique: false,
            ),
          );
        }
      }
    }
    return indexes;
  }

  String _toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return (match.start == 0 ? '' : '_') + match.group(1)!.toLowerCase();
    }).toLowerCase();
  }
}

class _IndexInfo {
  final String name;
  final String fields;
  final bool unique;
  _IndexInfo({required this.name, required this.fields, this.unique = false});
}
