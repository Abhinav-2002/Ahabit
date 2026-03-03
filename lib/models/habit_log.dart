import 'package:hive/hive.dart';

part 'habit_log.g.dart';

@HiveType(typeId: 1)
class HabitLog extends HiveObject {
  @HiveField(0)
  String habitId;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool isPunched;

  @HiveField(3)
  DateTime? completedAt;

  HabitLog({
    required this.habitId,
    required this.date,
    this.isPunched = true,
    this.completedAt,
  });
}
