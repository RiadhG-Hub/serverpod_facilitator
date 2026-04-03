import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class User {
  @PgPrimaryKey()
  int? id;
  
  @PgVarchar(255)
  @PgUnique()
  String email;
  
  @PgText()
  String name;
  
  @PgTimestamp()
  DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });
}
