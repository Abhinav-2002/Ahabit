import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  int colorIndex;

  @HiveField(5)
  String frequency;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isHidden;

  @HiveField(8)
  int sortOrder;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.colorIndex,
    required this.frequency,
    required this.createdAt,
    this.isHidden = false,
    this.sortOrder = 0,
  });
}
