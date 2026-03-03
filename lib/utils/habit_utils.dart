import '../models/habit.dart';

bool habitExistedOnDate(Habit habit, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final created = DateTime(
    habit.createdAt.year,
    habit.createdAt.month,
    habit.createdAt.day,
  );
  return !day.isBefore(created);
}
