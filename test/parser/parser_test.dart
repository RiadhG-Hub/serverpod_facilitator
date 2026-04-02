

import 'package:test/test.dart';
import 'package:serverpod_facilitator/parser/parser.dart';
import 'package:serverpod_facilitator/models/schema.dart';

void main() {
  final parser = SchemaParser();

  test('parse simple class with annotations', () {
    const code = '''
import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class User {
  @PgVarchar(255)
  String name;

  @PgUnique()
  String email;

  @PgDefault('now()')
  DateTime createdAt;
}
''';

    final models = parser.parseFile(code);
    expect(models.length, 1);
    final user = models.first;
    expect(user.name, 'User');
    expect(user.fields.length, 3);

    final nameField = user.fields.firstWhere((f) => f.name == 'name');
    expect(nameField.dartType, 'String');
    expect(nameField.annotations.any((a) => a is VarcharAnnotation), true);
    expect((nameField.annotations.firstWhere((a) => a is VarcharAnnotation) as VarcharAnnotation).length, 255);

    final emailField = user.fields.firstWhere((f) => f.name == 'email');
    expect(emailField.annotations.any((a) => a is UniqueAnnotation), true);

    final createdField = user.fields.firstWhere((f) => f.name == 'createdAt');
    expect(createdField.annotations.any((a) => a is DefaultAnnotation), true);
    expect((createdField.annotations.firstWhere((a) => a is DefaultAnnotation) as DefaultAnnotation).value, 'now()');
  });

  test('ignore classes without ServerpodModel annotation', () {
    const code = '''
class NotAModel {
  String name;
}
''';
    final models = parser.parseFile(code);
    expect(models.isEmpty, true);
  });
}
