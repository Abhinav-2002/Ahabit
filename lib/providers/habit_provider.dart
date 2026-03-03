import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/widget_helper.dart';
import '../services/notification_service.dart';
import '../utils/habit_utils.dart';

class HabitProvider extends ChangeNotifier {
  final Box<Habit> _habitsBox = Hive.box<Habit>('habits');
  final Box<HabitLog> _logsBox = Hive.box<HabitLog>('habitLogs');
  final _uuid = const Uuid();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Habit> get habits {
    final list = _habitsBox.values.where((h) => !h.isHidden).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<Habit> get visibleHabits => habits.where((h) => !h.isHidden).toList();

  List<HabitLog> getRecordsForHabit(String habitId) {
    return _logsBox.values.where((r) => r.habitId == habitId).toList();
  }

  HabitLog? getRecordForDate(String habitId, DateTime date) {
    try {
      return _logsBox.values.firstWhere(
        (r) => r.habitId == habitId && _isSameDay(r.date, date)
      );
    } catch (e) {
      return null;
    }
  }

  bool isHabitCompletedToday(String habitId) {
    final today = DateTime.now();
    final record = getRecordForDate(habitId, today);
    return record?.isPunched ?? false;
  }

  Future<void> toggleHabit(String habitId, DateTime date) async {
    final existingLogUrl = _logsBox.values.toList().indexWhere(
      (l) => l.habitId == habitId && _isSameDay(l.date, date)
    );

    if (existingLogUrl >= 0) {
      final log = _logsBox.getAt(existingLogUrl)!;
      log.isPunched = !log.isPunched;
      log.completedAt = log.isPunched ? DateTime.now() : null;
      await log.save();
    } else {
      final newLog = HabitLog(
        habitId: habitId,
        date: date,
        isPunched: true,
        completedAt: DateTime.now(),
      );
      await _logsBox.add(newLog);
    }
    notifyListeners();

    // Update widget immediately (real-time)
    WidgetHelper.triggerWidgetUpdate();

    // Reschedule streak protection with latest streak count
    _reschedulStreakProtection();
  }

  Future<void> toggleHabitById(String habitId) async {
    final today = DateTime.now();
    
    final existingLogUrl = _logsBox.values.toList().indexWhere(
      (l) => l.habitId == habitId && _isSameDay(l.date, today)
    );

    if (existingLogUrl >= 0) {
      final log = _logsBox.getAt(existingLogUrl)!;
      log.isPunched = !log.isPunched;
      log.completedAt = log.isPunched ? DateTime.now() : null;
      await log.save();
    } else {
      final newLog = HabitLog(
        habitId: habitId,
        date: today,
        isPunched: true,
        completedAt: DateTime.now(),
      );
      await _logsBox.add(newLog);
    }
    notifyListeners();
    WidgetHelper.triggerWidgetUpdate();
  }

  void _reschedulStreakProtection() async {
    try {
      final prefs = await _getPrefs();
      final userName = prefs.getString('user_name') ?? 'there';
      final streak = calculateCurrentStreak();
      final ns = NotificationService();
      if (streak >= 1) {
        await ns.scheduleStreakProtection(
          currentStreak: streak,
          userName: userName,
        );
      } else {
        await ns.cancelStreakWarnings();
      }
    } catch (e) {
      debugPrint('Error rescheduling streak protection: $e');
    }
  }

  // Cache prefs to avoid repeated getInstance calls
  static Future<dynamic> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }


  Future<void> addHabit(String name, String icon, int colorValue, {int colorIndex = 0, String frequency = 'daily'}) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      colorValue: colorValue,
      colorIndex: colorIndex,
      frequency: frequency,
      createdAt: DateTime.now(),
      sortOrder: habits.length,
    );
    await _habitsBox.put(habit.id, habit);
    notifyListeners();
    WidgetHelper.triggerWidgetUpdate();
  }

  Future<void> updateHabit(Habit habit) async {
    await habit.save();
    notifyListeners();
    WidgetHelper.triggerWidgetUpdate();
  }

  Future<void> deleteHabit(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit != null) {
      habit.isHidden = true;
      await habit.save();
      
      // Delete associated records
      final recordsToDelete = _logsBox.values.where((r) => r.habitId == habitId).toList();
      for (final record in recordsToDelete) {
        await record.delete();
      }
      notifyListeners();
      WidgetHelper.triggerWidgetUpdate();
    }
  }

  Future<void> reorderHabits(List<Habit> newOrder) async {
    for (int i = 0; i < newOrder.length; i++) {
      newOrder[i].sortOrder = i;
      await newOrder[i].save();
    }
    notifyListeners();
    WidgetHelper.triggerWidgetUpdate();
  }

  Future<void> toggleHabitVisibility(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit != null) {
      habit.isHidden = !habit.isHidden;
      await habit.save();
      notifyListeners();
      WidgetHelper.triggerWidgetUpdate();
    }
  }

  // --- PERFECT COMPLETION CALCULATIONS ---

  int getCompletedCountForDate(DateTime date) {
    if (visibleHabits.isEmpty) return 0;
    
    final habitsOnDate = visibleHabits.where((h) => habitExistedOnDate(h, date)).toList();
    if (habitsOnDate.isEmpty) return 0;

    return habitsOnDate.where((h) =>
      _logsBox.values.any((l) =>
        l.habitId == h.id &&
        _isSameDay(l.date, date) &&
        l.isPunched == true
      )
    ).length;
  }

  bool isDayComplete(DateTime date) {
    if (visibleHabits.isEmpty) return false;
    
    final habitsOnDate = visibleHabits.where((h) => habitExistedOnDate(h, date)).toList();
    if (habitsOnDate.isEmpty) return false;

    return habitsOnDate.every((habit) =>
      _logsBox.values.any((log) =>
        log.habitId == habit.id &&
        _isSameDay(log.date, date) &&
        log.isPunched == true
      )
    );
  }

  bool isDayPartial(DateTime date) {
    if (visibleHabits.isEmpty) return false;
    
    final habitsOnDate = visibleHabits.where((h) => habitExistedOnDate(h, date)).toList();
    if (habitsOnDate.isEmpty) return false;

    final doneCount = habitsOnDate.where((habit) =>
      _logsBox.values.any((log) =>
        log.habitId == habit.id &&
        _isSameDay(log.date, date) &&
        log.isPunched == true
      )
    ).length;
    
    return doneCount > 0 && doneCount < habitsOnDate.length;
  }

  int calculateCurrentStreak() {
    int streak = 0;
    DateTime check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    
    // Earliest created habit date
    DateTime? earliestDate;
    if (visibleHabits.isNotEmpty) {
      earliestDate = visibleHabits
          .map((h) => DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day))
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }
    
    while (true) {
      if (earliestDate != null && check.isBefore(earliestDate)) {
        break; // Stop if there were no habits
      }

      final anyDone = _logsBox.values.any((log) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        return logDate.isAtSameMomentAs(check) &&
          log.isPunched == true &&
          !log.habitId.startsWith('FREEZE_');
      });
      
      final freezeKey = 'FREEZE_${DateFormat('yyyy-MM-dd').format(check)}';
      final isFrozen = _logsBox.values.any((l) => l.habitId == freezeKey);
      
      if (anyDone || isFrozen) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int calculateBestStreak() {
    if (_logsBox.isEmpty) return 0;
    
    final allDates = _logsBox.values
      .where((l) => l.isPunched == true && !l.habitId.startsWith('FREEZE_'))
      .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
      .toSet()
      .toList()
      ..sort();
    
    if (allDates.isEmpty) return 0;
    
    int best = 1;
    int current = 1;
    
    for (int i = 1; i < allDates.length; i++) {
      final diff = allDates[i].difference(allDates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  int calculateHabitStreak(String habitId) {
    int streak = 0;
    DateTime check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final habit = _habitsBox.get(habitId);
    if (habit == null) return 0;
    final created = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    
    while (true) {
      if (check.isBefore(created)) {
        break;
      }

      final done = _logsBox.values.any((log) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        return log.habitId == habitId &&
          logDate.isAtSameMomentAs(check) &&
          log.isPunched == true;
      });
      
      if (done) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int getTodayCompletionPercent() {
    final today = DateTime.now();
    if (visibleHabits.isEmpty) return 0;
    
    final habitsForToday = visibleHabits.where((h) => habitExistedOnDate(h, today)).toList();
    if (habitsForToday.isEmpty) return 0;

    final done = habitsForToday.where((h) =>
      _logsBox.values.any((l) =>
        l.habitId == h.id &&
        _isSameDay(l.date, today) &&
        l.isPunched == true
      )
    ).length;
    
    return (done / habitsForToday.length * 100).round();
  }

  int getTodayDoneCount() {
    final today = DateTime.now();
    final habitsForToday = visibleHabits.where((h) => habitExistedOnDate(h, today)).toList();
    return habitsForToday.where((h) =>
      _logsBox.values.any((l) =>
        l.habitId == h.id &&
        _isSameDay(l.date, today) &&
        l.isPunched == true
      )
    ).length;
  }

  int getTotalHabitsCount() {
    return visibleHabits.length;
  }

  List<bool?> getHabitWeekCompletion(String habitId) {
    final today = DateTime.now();
    final habit = _habitsBox.get(habitId);
    if (habit == null) return List.filled(7, false);

    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      if (!habitExistedOnDate(habit, day)) {
        return null;
      }
      return _logsBox.values.any((l) =>
        l.habitId == habitId &&
        _isSameDay(l.date, day) &&
        l.isPunched == true
      );
    });
  }

  Map<int, bool?> getHabitMonthCompletion(String habitId) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    final habit = _habitsBox.get(habitId);
    
    final result = <int, bool?>{};
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(now.year, now.month, d);
      if (habit != null && !habitExistedOnDate(habit, date)) {
        result[d] = null;
      } else {
        result[d] = _logsBox.values.any((l) =>
          l.habitId == habitId &&
          _isSameDay(l.date, date) &&
          l.isPunched == true
        );
      }
    }
    return result;
  }

  int getTotalCompletions(String habitId) {
    return getRecordsForHabit(habitId).where((r) => r.isPunched).length;
  }

  Map<String, int?> getMonthlyStats(String habitId, int year, int month) {
    final stats = <String, int?>{};
    final habit = _habitsBox.get(habitId);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      if (habit != null && !habitExistedOnDate(habit, date)) {
        stats[d.toString()] = null;
      } else {
        final isPunched = _logsBox.values.any((l) =>
          l.habitId == habitId &&
          _isSameDay(l.date, date) &&
          l.isPunched == true
        );
        stats[d.toString()] = isPunched ? 1 : 0;
      }
    }
    
    return stats;
  }

  Map<String, dynamic> getYearlyStats(String habitId, int year) {
    final monthlyData = <int, int>{};
    int totalCompleted = 0;
    
    final habit = _habitsBox.get(habitId);

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      int monthCompleted = 0;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        if (habit != null && habitExistedOnDate(habit, date)) {
          final isPunched = _logsBox.values.any((l) =>
              l.habitId == habitId &&
              _isSameDay(l.date, date) &&
              l.isPunched == true
          );
          if (isPunched) {
            monthCompleted++;
            totalCompleted++;
          }
        }
      }
      
      monthlyData[month] = monthCompleted;
    }
    
    return {
      'monthly': monthlyData,
      'total': totalCompleted,
    };
  }

  String getRank() {
    int totalCompletions = 0;
    for (final habit in visibleHabits) {
      totalCompletions += getTotalCompletions(habit.id);
    }

    if (totalCompletions >= 1000) return 'Legend';
    if (totalCompletions >= 500) return 'Master';
    if (totalCompletions >= 200) return 'Expert';
    if (totalCompletions >= 100) return 'Pro';
    if (totalCompletions >= 50) return 'Rising Star';
    if (totalCompletions >= 20) return 'Committed';
    if (totalCompletions >= 10) return 'Beginner';
    return 'Starter';
  }
}
