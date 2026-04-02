

import 'package:test/test.dart';
import 'package:serverpod_facilitator/mapper/mapper.dart';
import 'package:serverpod_facilitator/models/schema.dart';

void main() {
  final mapper = YamlMapper();

  test('map simple model to yaml', () {
    final model = ModelDefinition(
      name: 'User',
      fields: [
        FieldDefinition(
          name: 'name',
          dartType: 'String',
          isNullable: false,
          annotations: [VarcharAnnotation(255)],
        ),
        FieldDefinition(
          name: 'email',
          dartType: 'String',
          isNullable: false,
          annotations: [UniqueAnnotation()],
        ),
      ],
    );

    final yaml = mapper.mapToYaml(model);
    expect(yaml, contains('class: User'));
    expect(yaml, contains('table: user'));
    expect(yaml, contains('name: String, database=varchar(255)'));
    expect(yaml, contains('email: String'));
    expect(yaml, contains('user_email_unique:'));
    expect(yaml, contains('fields: email'));
    expect(yaml, contains('unique: true'));
  });
}
