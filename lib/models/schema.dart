class ModelDefinition {
  final String name;
  final List<FieldDefinition> fields;
  final List<String> customSql;

  ModelDefinition({
    required this.name,
    required this.fields,
    this.customSql = const [],
  });
}

class FieldDefinition {
  final String name;
  final String dartType;
  final bool isNullable;
  final List<AnnotationDefinition> annotations;

  FieldDefinition({
    required this.name,
    required this.dartType,
    required this.isNullable,
    this.annotations = const [],
  });
}

abstract class AnnotationDefinition {}

class VarcharAnnotation extends AnnotationDefinition {
  final int length;
  VarcharAnnotation(this.length);
}

class TextAnnotation extends AnnotationDefinition {}

class UniqueAnnotation extends AnnotationDefinition {}

class IndexAnnotation extends AnnotationDefinition {
  final String? name;
  IndexAnnotation(this.name);
}

class DefaultAnnotation extends AnnotationDefinition {
  final String value;
  DefaultAnnotation(this.value);
}

class PrimaryKeyAnnotation extends AnnotationDefinition {}

class ForeignKeyAnnotation extends AnnotationDefinition {
  final String table;
  final String column;
  ForeignKeyAnnotation(this.table, this.column);
}

class BigIntAnnotation extends AnnotationDefinition {}

class JsonAnnotation extends AnnotationDefinition {}

class JsonbAnnotation extends AnnotationDefinition {}

class UuidAnnotation extends AnnotationDefinition {}

class NumericAnnotation extends AnnotationDefinition {
  final int precision;
  final int scale;
  NumericAnnotation(this.precision, this.scale);
}

class TimestampAnnotation extends AnnotationDefinition {}

class TimestamptzAnnotation extends AnnotationDefinition {}

class CustomSqlAnnotation extends AnnotationDefinition {
  final String sql;
  CustomSqlAnnotation(this.sql);
}
