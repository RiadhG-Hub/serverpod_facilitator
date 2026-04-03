import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../models/schema.dart';

class SchemaParser {
  List<ModelDefinition> parseFile(String content) {
    final result = parseString(content: content);
    final visitor = _SchemaVisitor();
    result.unit.visitChildren(visitor);
    return visitor.models;
  }
}

class _SchemaVisitor extends RecursiveAstVisitor<void> {
  final List<ModelDefinition> models = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    Annotation? serverpodModelAnnotation;
    try {
      serverpodModelAnnotation = node.metadata.firstWhere(
        (m) => m.name.name == 'ServerpodModel',
      );
    } catch (e) {
      return;
    }

    final customSql = <String>[];
    final args = serverpodModelAnnotation.arguments?.arguments;
    if (args != null) {
      for (final arg in args) {
        if (arg is NamedExpression && arg.name.label.name == 'customSql') {
          if (arg.expression is ListLiteral) {
            final list = arg.expression as ListLiteral;
            for (final element in list.elements) {
              if (element is StringLiteral) {
                final val = element.stringValue;
                if (val != null) customSql.add(val);
              }
            }
          }
        }
      }
    }

    final fields = <FieldDefinition>[];
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        final type = member.fields.type;
        final annotations = _parseAnnotations(member.metadata);

        for (final variable in member.fields.variables) {
          fields.add(FieldDefinition(
            name: variable.name.lexeme,
            dartType: _getBaseType(type),
            isNullable: type?.toSource().endsWith('?') ?? false,
            annotations: annotations,
          ));
        }
      }
    }

    models.add(ModelDefinition(
      name: node.name.lexeme,
      fields: fields,
      customSql: customSql,
    ));
  }

  String _getBaseType(TypeAnnotation? type) {
    if (type == null) return 'dynamic';
    final source = type.toSource();
    return source.endsWith('?')
        ? source.substring(0, source.length - 1)
        : source;
  }

  List<AnnotationDefinition> _parseAnnotations(NodeList<Annotation> metadata) {
    final results = <AnnotationDefinition>[];
    for (final annotation in metadata) {
      final name = annotation.name.name;
      final args = annotation.arguments?.arguments;

      try {
        switch (name) {
          case 'PgVarchar':
            if (args != null && args.isNotEmpty) {
              final length = (args.first as IntegerLiteral).value;
              if (length != null) results.add(VarcharAnnotation(length));
            }
            break;
          case 'PgText':
            results.add(TextAnnotation());
            break;
          case 'PgInt':
            results.add(IntAnnotation());
            break;
          case 'PgBoolean':
            results.add(BooleanAnnotation());
            break;
          case 'PgEnum':
            results.add(EnumAnnotation());
            break;
          case 'Realtime':
            results.add(RealtimeAnnotation());
            break;
          case 'PgUnique':
            results.add(UniqueAnnotation());
            break;
          case 'PgIndex':
            String? indexName;
            if (args != null && args.isNotEmpty) {
              final firstArg = args.first;
              if (firstArg is NamedExpression &&
                  firstArg.name.label.name == 'name') {
                indexName = (firstArg.expression as StringLiteral).stringValue;
              } else if (firstArg is StringLiteral) {
                indexName = firstArg.stringValue;
              }
            }
            results.add(IndexAnnotation(indexName));
            break;
          case 'PgDefault':
            if (args != null && args.isNotEmpty) {
              final value = (args.first as StringLiteral).stringValue;
              if (value != null) results.add(DefaultAnnotation(value));
            }
            break;
          case 'PgPrimaryKey':
            results.add(PrimaryKeyAnnotation());
            break;
          case 'PgForeignKey':
            if (args != null && args.length >= 2) {
              final table = (args[0] as StringLiteral).stringValue;
              final column = (args[1] as StringLiteral).stringValue;
              if (table != null && column != null) {
                results.add(ForeignKeyAnnotation(table, column));
              }
            }
            break;
          case 'PgBigInt':
            results.add(BigIntAnnotation());
            break;
          case 'PgJson':
            results.add(JsonAnnotation());
            break;
          case 'PgJsonb':
            results.add(JsonbAnnotation());
            break;
          case 'PgUuid':
            results.add(UuidAnnotation());
            break;
          case 'PgNumeric':
            if (args != null && args.length >= 2) {
              final precision = (args[0] as IntegerLiteral).value;
              final scale = (args[1] as IntegerLiteral).value;
              if (precision != null && scale != null) {
                results.add(NumericAnnotation(precision, scale));
              }
            }
            break;
          case 'PgTimestamp':
            results.add(TimestampAnnotation());
            break;
          case 'PgTimestamptz':
            results.add(TimestamptzAnnotation());
            break;
          case 'PgCustomSql':
            if (args != null && args.isNotEmpty) {
              final sql = (args.first as StringLiteral).stringValue;
              if (sql != null) results.add(CustomSqlAnnotation(sql));
            }
            break;
          case 'Relation':
            String? relationName;
            if (args != null && args.isNotEmpty) {
              final firstArg = args.first;
              if (firstArg is NamedExpression &&
                  firstArg.name.label.name == 'name') {
                relationName =
                    (firstArg.expression as StringLiteral).stringValue;
              } else if (firstArg is StringLiteral) {
                relationName = firstArg.stringValue;
              }
            }
            results.add(RelationAnnotation(name: relationName));
            break;
          case 'Parent':
            String? relation;
            if (args != null && args.isNotEmpty) {
              final firstArg = args.first;
              if (firstArg is NamedExpression &&
                  firstArg.name.label.name == 'relation') {
                relation = (firstArg.expression as StringLiteral).stringValue;
              } else if (firstArg is StringLiteral) {
                relation = firstArg.stringValue;
              }
            }
            results.add(ParentAnnotation(relation: relation));
            break;
        }
      } catch (e) {
        // Skip invalid annotations for now
      }
    }
    return results;
  }
}
