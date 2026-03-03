import 'package:hive/hive.dart';

part 'notice.g.dart';

@HiveType(typeId: 2)
class Notice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String message;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  String type; // 'rank', 'streak', 'complete', 'reminder'

  @HiveField(6)
  Map<String, dynamic>? data; // Additional data like rank name, streak count, etc.

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.data,
  });
}
