import '../models/schema.dart';

class ValidationResult {
  final List<String> errors = [];
  bool get isValid => errors.isEmpty;
}

class SchemaValidator {
  ValidationResult validate(List<ModelDefinition> models) {
    final result = ValidationResult();
    final allowedTypes = {
      'String',
      'int',
      'double',
      'bool',
      'DateTime',
      'ByteData',
      'Map<String, dynamic>',
      'List<int>',
      'List<String>',
      'List<double>',
      'List<bool>',
      'List<DateTime>',
    };

    for (final model in models) {
      for (final field in model.fields) {
        if (!allowedTypes.contains(field.dartType)) {
          if (field.dartType.startsWith('Map')) {
            result.errors.add(
                'Unsupported type ${field.dartType} in ${model.name}.${field.name}. Use @PgJson instead.');
          }
        }

        _validateAnnotations(model, field, result);
      }
    }
    return result;
  }

  void _validateAnnotations(
      ModelDefinition model, FieldDefinition field, ValidationResult result) {
    bool hasVarchar = field.annotations.any((a) => a is VarcharAnnotation);
    bool hasText = field.annotations.any((a) => a is TextAnnotation);
    bool hasJson = field.annotations.any((a) => a is JsonAnnotation || a is JsonbAnnotation);

    if (hasVarchar && hasText) {
      result.errors.add(
          'Conflicting annotations @PgVarchar and @PgText on ${model.name}.${field.name}.');
    }

    if (hasJson && !field.dartType.startsWith('Map')) {
      result.errors.add(
          '@PgJson/b should be used with Map types. Found ${field.dartType} in ${model.name}.${field.name}.');
    }
  }
}
