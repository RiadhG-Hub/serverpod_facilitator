

import '../annotations/annotations.dart';

@ServerpodModel()
class Profile {
  @PgVarchar(255)
  String name;

  @PgUnique()
  String bio;

  @PgDefault('now()')
  DateTime createdAt;
}
