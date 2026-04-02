

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
    final hasServerpodModel = node.metadata.any((m) => m.name.name == 'ServerpodModel');
    if (!hasServerpodModel) return;

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
    ));
  }

  String _getBaseType(TypeAnnotation? type) {
    if (type == null) return 'dynamic';
    final source = type.toSource();
    return source.endsWith('?') ? source.substring(0, source.length - 1) : source;
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
          case 'PgUnique':
            results.add(UniqueAnnotation());
            break;
          case 'PgIndex':
            String? indexName;
            if (args != null && args.isNotEmpty) {
              final firstArg = args.first;
              if (firstArg is NamedExpression && firstArg.name.label.name == 'name') {
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
        }
      } catch (e) {
        // Skip invalid annotations for now
      }
    }
    return results;
  }
}
