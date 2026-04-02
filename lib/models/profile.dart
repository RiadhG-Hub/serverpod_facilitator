import '../annotations/annotations.dart';

@ServerpodModel(customSql: [
  'CREATE INDEX profile_bio_trgm_idx ON profile USING gin (bio gin_trgm_ops);',
])
class Profile {
  @PgVarchar(255)
  late String name;

  @PgUnique()
  @PgText()
  late String bio;

  @PgBigInt()
  late int points;

  @PgJsonb()
  late Map<String, dynamic> metadata;

  @PgDefault('now()')
  late DateTime createdAt;
}
