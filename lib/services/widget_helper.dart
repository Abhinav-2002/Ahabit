import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';

class WidgetHelper {
  static const String appGroupId = 'group.com.habitpunch.app';
  static const String androidWidgetMediumName = 'HabitWidgetMediumProvider';
  static const String androidWidgetSmallName = 'HabitWidgetSmallProvider';
  static const String iOSWidgetName = 'HabitWidget';
  static const MethodChannel _methodChannel = MethodChannel('com.example.habit_punch/widget');

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Fire-and-forget widget update — never blocks UI
  static void triggerWidgetUpdate() {
    updateWidgetFromBoxes().catchError((e) {
      debugPrint('Widget update error: $e');
    });
  }

  /// Force immediate widget update - use when app starts or data changes
  static Future<void> forceWidgetUpdate() async {
    debugPrint('=== forceWidgetUpdate START ===');
    try {
      await updateWidgetFromBoxes();
      
      // Try MethodChannel first
      try {
        debugPrint('Calling MethodChannel commitAndUpdate...');
        final result = await _methodChannel.invokeMethod('commitAndUpdate');
        debugPrint('MethodChannel success, updated $result widgets');
      } catch (e) {
        debugPrint('MethodChannel failed: $e');
        debugPrint('Trying HomeWidget.updateWidget fallback...');
        
        // Fallback to home_widget package
        try {
          await HomeWidget.updateWidget(
            androidName: androidWidgetMediumName,
            iOSName: iOSWidgetName,
          );
          debugPrint('HomeWidget medium update success');
        } catch (e) {
          debugPrint('HomeWidget medium update failed: $e');
        }
        
        try {
          await HomeWidget.updateWidget(
            androidName: androidWidgetSmallName,
          );
          debugPrint('HomeWidget small update success');
        } catch (e) {
          debugPrint('HomeWidget small update failed: $e');
        }
      }
    } catch (e) {
      debugPrint('forceWidgetUpdate error: $e');
    }
    debugPrint('=== forceWidgetUpdate END ===');
  }

  /// Debug function to test widget data saving
  static Future<void> debugTestWidget() async {
    debugPrint('========== WIDGET DEBUG TEST ==========');
    
    // Test 1: Check Hive
    debugPrint('\n--- TEST 1: Hive Data ---');
    try {
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox<Habit>('habits');
      }
      final habitsBox = Hive.box<Habit>('habits');
      debugPrint('Habits in box: ${habitsBox.length}');
      for (final h in habitsBox.values.take(3)) {
        debugPrint('  - ${h.name} (hidden=${h.isHidden})');
      }
    } catch (e) {
      debugPrint('Hive error: $e');
    }
    
    // Test 2: Save test data
    debugPrint('\n--- TEST 2: Save Test Data ---');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('widget.streak', 999);
      await prefs.setInt('widget.done_count', 5);
      await prefs.setInt('widget.total_count', 10);
      await prefs.setString('widget.habits_json', '[{"id":"test","name":"Test Habit","icon":"🏃","todayDone":true}]');
      await prefs.setString('widget.pending_toggles', '[]');
      debugPrint('Test data saved!');
      
      // Verify
      final s = prefs.getInt('widget.streak');
      final h = prefs.getString('widget.habits_json');
      final p = prefs.getString('widget.pending_toggles');
      debugPrint('Verified: streak=$s, habits=$h, pending toggles=$p');
    } catch (e) {
      debugPrint('Save error: $e');
    }
    
    // Test 3: MethodChannel
    debugPrint('\n--- TEST 3: MethodChannel ---');
    try {
      final result = await _methodChannel.invokeMethod('commitAndUpdate');
      debugPrint('MethodChannel success! Updated $result widgets');
    } catch (e) {
      debugPrint('MethodChannel error: $e');
    }
    
    // Test 4: HomeWidget
    debugPrint('\n--- TEST 4: HomeWidget Package ---');
    try {
      await HomeWidget.updateWidget(
        androidName: androidWidgetMediumName,
        iOSName: iOSWidgetName,
      );
      debugPrint('HomeWidget medium success');
    } catch (e) {
      debugPrint('HomeWidget medium error: $e');
    }
    
    debugPrint('\n========== END DEBUG TEST ==========');
  }

  /// Self-contained widget update — reads directly from Hive boxes.
  static Future<void> updateWidgetFromBoxes() async {
    try {
      debugPrint('=== WIDGET UPDATE START ===');
      
      // Check Hive boxes
      debugPrint('Checking Hive boxes...');
      if (!Hive.isBoxOpen('habits')) {
        debugPrint('Opening habits box...');
        await Hive.openBox<Habit>('habits');
      }
      if (!Hive.isBoxOpen('habitLogs')) {
        debugPrint('Opening habitLogs box...');
        await Hive.openBox<HabitLog>('habitLogs');
      }

      final habitsBox = Hive.box<Habit>('habits');
      final logsBox = Hive.box<HabitLog>('habitLogs');
      final now = DateTime.now();

      debugPrint('Hive - habits count: ${habitsBox.length}');
      debugPrint('Hive - logs count: ${logsBox.length}');

      final habits = habitsBox.values.where((h) => !h.isHidden).toList();
      habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      debugPrint('Visible habits count: ${habits.length}');
      for (final h in habits) {
        debugPrint('  - ${h.name} (id=${h.id})');
      }

      // Calculate completion stats
      int completedToday = 0;
      for (final h in habits) {
        final done = logsBox.values.any((l) =>
          l.habitId == h.id && _isSameDay(l.date, now) && l.isPunched);
        if (done) completedToday++;
      }

      final totalToday = habits.length;
      final percentage = totalToday > 0
          ? (completedToday / totalToday * 100).round()
          : 0;

      debugPrint('Stats - completed: $completedToday, total: $totalToday, pct: $percentage');

      // Calculate streak
      int streak = 0;
      DateTime check = DateTime(now.year, now.month, now.day);
      while (true) {
        final anyDone = logsBox.values.any((log) {
          final logDate = DateTime(log.date.year, log.date.month, log.date.day);
          return logDate.isAtSameMomentAs(check) &&
            log.isPunched == true &&
            !log.habitId.startsWith('FREEZE_');
        });
        final freezeKey = 'FREEZE_${DateFormat('yyyy-MM-dd').format(check)}';
        final isFrozen = logsBox.values.any((l) => l.habitId == freezeKey);
        if (anyDone || isFrozen) {
          streak++;
          check = check.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      debugPrint('Streak: $streak');

      // Build habits JSON - include up to 7 habits
      final habitsJsonList = habits.take(7).map((h) => {
        'id': h.id,
        'name': h.name,
        'icon': h.icon,
        'todayDone': logsBox.values.any((l) =>
            l.habitId == h.id && _isSameDay(l.date, now) && l.isPunched),
      }).toList();
      final String habitsJson = jsonEncode(habitsJsonList);

      debugPrint('Habits JSON (${habitsJsonList.length} habits): $habitsJson');

      // Save data to SharedPreferences for the Android widget
      final prefs = await SharedPreferences.getInstance();
      
      debugPrint('WIDGET: Saving data to SharedPreferences...');
      await prefs.setInt('widget.streak', streak);
      await prefs.setInt('widget.done_count', completedToday);
      await prefs.setInt('widget.total_count', totalToday);
      await prefs.setInt('widget.completion_pct', percentage);
      await prefs.setString('widget.date_str', DateFormat('EEE, MMM d').format(now));
      await prefs.setString('widget.habits_json', habitsJson);
      await prefs.setString('widget.pending_toggles', '[]');

      // KEY LOG: Show exactly what was written so we can compare with Kotlin logs
      debugPrint('WIDGET WROTE: streak=$streak done=$completedToday/$totalToday pct=$percentage% habits=${habitsJsonList.length}');

      // Force SharedPreferences to disk BEFORE widget reads it
      try {
        debugPrint('Calling commitAndUpdate...');
        final result = await _methodChannel.invokeMethod('commitAndUpdate');
        debugPrint('commitAndUpdate success, updated $result widgets');
      } catch (e) {
        debugPrint('commitAndUpdate error: $e');
      }

    } catch (e, stack) {
      debugPrint('Widget error: $e');
      debugPrint('Stack: $stack');
    }
    debugPrint('=== WIDGET UPDATE END ===');
  }

  /// Provider-based widget update (backward compatible)
  static Future<void> updateWidget(HabitProvider habitProvider) async {
    await updateWidgetFromBoxes();
  }

  /// Sync pending toggles from widget back to Hive
  static Future<void> syncPendingToggles(HabitProvider habitProvider) async {
    try {
      // Ensure Hive is initialized (critical for background/resume scenarios)
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox<Habit>('habits');
      }
      if (!Hive.isBoxOpen('habitLogs')) {
        await Hive.openBox<HabitLog>('habitLogs');
      }
      
      final prefs = await SharedPreferences.getInstance();
      // Force fresh read — Kotlin widget writes outside Flutter's in-memory cache
      await prefs.reload();
      // The widget saves to 'widget.pending_toggles' (flutter prefix added by plugin)
      final pendingJson = prefs.getString('widget.pending_toggles') ?? '[]';
      final List<dynamic> pending = jsonDecode(pendingJson);

      if (pending.isEmpty) return;

      debugPrint('WIDGET SYNC: ${pending.length} pending toggles found: $pending');

      for (final habitId in pending) {
        debugPrint('WIDGET SYNC: processing toggle for habit: $habitId');
        await habitProvider.toggleHabitById(habitId as String);
      }

      // Clear pending toggles after sync
      await prefs.setString('widget.pending_toggles', '[]');
      debugPrint('WIDGET SYNC: pending toggles cleared');
      
      // Force widget update to reflect synced changes (both widget and app now in sync)
      await forceWidgetUpdate();
    } catch (e, stack) {
      debugPrint('WIDGET SYNC ERROR: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Future<void> handleWidgetTap(String? habitId) async {
    if (habitId == null || habitId.isEmpty) return;
    await HomeWidget.saveWidgetData('tapped_habit_id', habitId);
  }

  static Future<String?> getTappedHabitId() async {
    final habitId = await HomeWidget.getWidgetData('tapped_habit_id');
    if (habitId != null) {
      await HomeWidget.saveWidgetData('tapped_habit_id', null);
    }
    return habitId;
  }

  static Future<void> clearWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('widget_data');
    await HomeWidget.saveWidgetData('widget_data', null);
    
    await HomeWidget.updateWidget(
      androidName: androidWidgetMediumName,
      iOSName: iOSWidgetName,
    );
    await HomeWidget.updateWidget(
      androidName: androidWidgetSmallName,
    );
  }
}
