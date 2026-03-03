import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/habit_utils.dart'; // Added this import

class HabitCalendar extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> records;

  const HabitCalendar({
    super.key,
    required this.habit,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    // Get completed dates set
    final completedDates = records
      .where((r) => r.isPunched)
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet();

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Empty cells before first day
              ...List.generate(firstWeekday % 7, (index) {
                return const SizedBox(width: 32, height: 32);
              }),

              // Days of month
              ...List.generate(daysInMonth, (index) {
                final day = index + 1;
                final date = DateTime(now.year, now.month, day);
                final habitExisted = habitExistedOnDate(habit, date);
                final isCompleted = habitExisted && completedDates.contains(date);
                final isToday = day == now.day;

                // For days before the habit existed, show an empty/grey square
                if (!habitExisted) {
                   return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }

                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                      ? Color(habit.colorValue)
                      : isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                      ? Border.all(
                          color: Color(habit.colorValue),
                          width: 2,
                        )
                      : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                          ? Colors.white
                          : isDark
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Month label
        Text(
          DateFormat('MMMM yyyy').format(now),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF888888),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
