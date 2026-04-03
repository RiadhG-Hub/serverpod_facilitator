import 'package:serverpod_facilitator/annotations/annotations.dart';

@ServerpodModel()
class Post {
  @PgPrimaryKey()
  int? id;
  
  @PgText()
  String content;
  
  @PgTimestamp()
  DateTime postedAt;
  
  @PgForeignKey('user', 'id')
  int userId;

  Post({
    this.id,
    required this.content,
    required this.postedAt,
    required this.userId,
  });
}
