import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../widgets/habit_calendar.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'weekly'; // weekly, monthly, yearly

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitProvider = context.watch<HabitProvider>();
    final habits = habitProvider.habits;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Statistics',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 52),
                ],
              ),
            ),

            // Period selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildPeriodTab('Weekly', 'weekly'),
                    _buildPeriodTab('Monthly', 'monthly'),
                    _buildPeriodTab('Yearly', 'yearly'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats content
            Expanded(
              child: habits.isEmpty
                ? _buildEmptyState()
                : _buildStatsContent(habitProvider, habits),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _selectedPeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF111111) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected 
                ? Colors.white 
                : (isDark ? const Color(0xFF888888) : const Color(0xFFAAAAAA)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(HabitProvider provider, List<Habit> habits) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Overall stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Habits',
                  habits.length.toString(),
                  Icons.format_list_bulleted,
                  const Color(0xFF4DABF7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  provider.getCompletedCountForDate(DateTime.now()).toString(),
                  Icons.check_circle,
                  const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Best Streak',
                  _getBestStreak(provider, habits).toString(),
                  Icons.local_fire_department,
                  const Color(0xFFFF9F43),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Days',
                  _getTotalCompletions(provider, habits).toString(),
                  Icons.calendar_today,
                  const Color(0xFFFF6584),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Habit calendars
          ...habits.map((habit) => _buildHabitStatsCard(provider, habit)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitStatsCard(HabitProvider provider, Habit habit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = provider.calculateHabitStreak(habit.id);
    final total = provider.getTotalCompletions(habit.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Habit header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(habit.colorValue).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$total completions · $streak day streak',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF888888),
                        ),
                      ),
                      if (_getBestTime(habit.id).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getBestTime(habit.id),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Calendar
          HabitCalendar(
            habit: habit,
            records: provider.getRecordsForHabit(habit.id),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  int _getBestStreak(HabitProvider provider, List<Habit> habits) {
    return provider.calculateBestStreak();
  }

  String _getBestTime(String habitId) {
    if (!Hive.isBoxOpen('habitLogs')) return '';
    final logsBox = Hive.box<HabitLog>('habitLogs');
    final completedLogs = logsBox.values
      .where((l) =>
        l.habitId == habitId &&
        l.isPunched == true &&
        l.completedAt != null)
      .toList();

    if (completedLogs.isEmpty) return '';

    // Count by hour
    final hourCounts = <int, int>{};
    for (final log in completedLogs) {
      final hour = log.completedAt!.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    // Find most common hour
    final bestHour = hourCounts.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

    // Convert to readable time
    final period = bestHour >= 12 ? 'PM' : 'AM';
    final display = bestHour > 12
      ? bestHour - 12
      : bestHour == 0 ? 12 : bestHour;

    return '⏰ Usually done at $display $period';
  }

  int _getTotalCompletions(HabitProvider provider, List<Habit> habits) {
    int total = 0;
    for (final habit in habits) {
      total += provider.getTotalCompletions(habit.id);
    }
    return total;
  }
}
