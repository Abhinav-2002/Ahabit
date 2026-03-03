import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/user_provider.dart';
import '../utils/habit_utils.dart';

class CalendarModal extends StatefulWidget {
  const CalendarModal({super.key});

  @override
  State<CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends State<CalendarModal> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitProvider = context.watch<HabitProvider>();
    final userProvider = context.watch<UserProvider>();
    final visibleHabits = habitProvider.visibleHabits;

    final currentStreak = _calculateCurrentStreak(habitProvider);
    final bestStreak = userProvider.bestStreak;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Streak header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStreakBadge(
                  icon: '🔥',
                  label: 'Current Streak',
                  value: '$currentStreak days',
                  color: const Color(0xFFFF9F43),
                ),
                const SizedBox(width: 16),
                _buildStreakBadge(
                  icon: '⚡',
                  label: 'Best Streak',
                  value: '$bestStreak days',
                  color: const Color(0xFFFFD166),
                ),
              ],
            ),
          ),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF888888),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCalendarGrid(habitProvider, visibleHabits),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('All done', const Color(0xFF4CAF50)),
                const SizedBox(width: 24),
                _buildLegendItem('Partial', const Color(0xFFFFD166)),
                const SizedBox(width: 24),
                _buildLegendItem('None', isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF888888),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(HabitProvider provider, List habits) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = daysInMonth + firstWeekday;
    final rows = (totalDays / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final dayIndex = rowIndex * 7 + colIndex - firstWeekday;
              
              if (dayIndex < 0 || dayIndex >= daysInMonth) {
                return const SizedBox(width: 40, height: 40);
              }

              final day = dayIndex + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              
              // Only count habits that existed on this date
              final activeHabitsOnDate = habits.where((h) => habitExistedOnDate(h, date)).toList();
              final totalHabits = activeHabitsOnDate.length;
              final completedCount = provider.getCompletedCountForDate(date);
              
              DateStatus status;
              if (totalHabits == 0) {
                status = DateStatus.empty;
              } else if (completedCount == 0) {
                status = DateStatus.none;
              } else if (completedCount == totalHabits) {
                status = DateStatus.all;
              } else {
                status = DateStatus.partial;
              }

              final isToday = day == DateTime.now().day &&
                  _currentMonth.month == DateTime.now().month &&
                  _currentMonth.year == DateTime.now().year;

              return _buildDayCell(day, status, isToday);
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(int day, DateStatus status, bool isToday) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color textColor;
    Widget? overlay;

    switch (status) {
      case DateStatus.all:
        bgColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        break;
      case DateStatus.partial:
        bgColor = const Color(0xFFFFD166);
        textColor = const Color(0xFF7A5A00);
        overlay = Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
        break;
      case DateStatus.none:
        bgColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0);
        textColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
        break;
      case DateStatus.empty:
        bgColor = Colors.transparent;
        textColor = const Color(0xFFAAAAAA);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday
          ? Border.all(color: const Color(0xFF111111), width: 2)
          : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (overlay != null) overlay,
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  int _calculateCurrentStreak(HabitProvider provider) {
    int streak = 0;
    DateTime date = DateTime.now();
    
    while (true) {
      final completed = provider.getCompletedCountForDate(date);
      if (completed > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}

enum DateStatus { all, partial, none, empty }
