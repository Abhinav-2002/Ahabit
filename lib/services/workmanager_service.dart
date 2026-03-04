import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'widget_helper.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

// Workmanager task names
const String incompleteHabitsTask = 'incomplete_habits_check';
const String midnightResetTask = 'midnight_widget_reset';
const String widgetSyncTask = 'widget_sync';

// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Workmanager task executed: $task');
    
    if (task == incompleteHabitsTask) {
      return await _checkAndNotifyIncompleteHabits();
    }
    
    if (task == midnightResetTask) {
      return await _midnightWidgetReset();
    }

    if (task == widgetSyncTask) {
      return await _widgetSyncTask();
    }

    return Future.value(true);
  });
}

// Background sync: apply pending widget toggles to Hive, then refresh widget
Future<bool> _widgetSyncTask() async {
  try {
    debugPrint('WIDGET SYNC TASK: starting');

    // Initialize Hive safely
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitLogAdapter());
    if (!Hive.isBoxOpen('habits')) await Hive.openBox<Habit>('habits');
    if (!Hive.isBoxOpen('habitLogs')) await Hive.openBox<HabitLog>('habitLogs');

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    // Apply pending toggles from widget to Hive
    final pendingJson = prefs.getString('widget.pending_toggles') ?? '[]';
    final List<dynamic> pending = jsonDecode(pendingJson);

    if (pending.isNotEmpty) {
      final logsBox = Hive.box<HabitLog>('habitLogs');
      final now = DateTime.now();

      for (final habitId in pending) {
        final id = habitId as String;
        final existingIdx = logsBox.values.toList().indexWhere((l) =>
            l.habitId == id &&
            l.date.year == now.year &&
            l.date.month == now.month &&
            l.date.day == now.day);

        if (existingIdx >= 0) {
          final log = logsBox.getAt(existingIdx)!;
          log.isPunched = !log.isPunched;
          log.completedAt = log.isPunched ? now : null;
          await log.save();
        } else {
          await logsBox.add(HabitLog(
            habitId: id,
            date: now,
            isPunched: true,
            completedAt: now,
          ));
        }
      }

      await prefs.setString('widget.pending_toggles', '[]');
      debugPrint('WIDGET SYNC TASK: applied ${pending.length} toggle(s) to Hive');
    }

    // Rebuild filtered widget data from Hive
    await WidgetHelper.updateWidgetFromBoxes();

    // HomeWidget.updateWidget fallback to ensure widget redraws
    try {
      await HomeWidget.updateWidget(
        androidName: WidgetHelper.androidWidgetMediumName,
        iOSName: WidgetHelper.iOSWidgetName,
      );
      await HomeWidget.updateWidget(
        androidName: WidgetHelper.androidWidgetSmallName,
      );
    } catch (e) {
      debugPrint('WIDGET SYNC TASK: HomeWidget.updateWidget failed (non-fatal): $e');
    }

    debugPrint('WIDGET SYNC TASK: completed successfully');
    return true;
  } catch (e, stack) {
    debugPrint('WIDGET SYNC TASK ERROR: $e');
    debugPrint('Stack: $stack');
    return false;
  }
}

// Check incomplete habits and show notification
Future<bool> _checkAndNotifyIncompleteHabits() async {
  try {
    // Initialize Hive for background access
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitLogAdapter());
    }
    
    // Open boxes
    if (!Hive.isBoxOpen('habits')) {
      await Hive.openBox<Habit>('habits');
    }
    if (!Hive.isBoxOpen('habitLogs')) {
      await Hive.openBox<HabitLog>('habitLogs');
    }
    
    final habitsBox = Hive.box<Habit>('habits');
    final logsBox = Hive.box<HabitLog>('habitLogs');
    final prefs = await SharedPreferences.getInstance();
    
    // Check if feature is enabled
    final enabled = prefs.getBool('incomplete_reminders_enabled') ?? false;
    if (!enabled) {
      debugPrint('Incomplete reminders disabled, skipping');
      return true;
    }
    
    // Check current time - stop after 10pm
    final now = DateTime.now();
    if (now.hour >= 22) {
      debugPrint('After 10pm, skipping incomplete habits check');
      return true;
    }
    
    // Get all non-hidden habits
    final habits = habitsBox.values.where((h) => !h.isHidden).toList();
    if (habits.isEmpty) {
      debugPrint('No habits found');
      return true;
    }
    
    // Check which habits are NOT done today
    final today = DateTime(now.year, now.month, now.day);
    final incompleteHabits = <String>[];
    
    for (final habit in habits) {
      // Check if habit was punched today
      final isDoneToday = logsBox.values.any((log) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        return log.habitId == habit.id && 
               logDate.isAtSameMomentAs(today) && 
               log.isPunched;
      });
      
      if (!isDoneToday) {
        incompleteHabits.add('${habit.icon} ${habit.name}');
      }
    }
    
    // If all habits are done, don't notify
    if (incompleteHabits.isEmpty) {
      debugPrint('All habits completed, no notification needed');
      return true;
    }
    
    // Show notification
    final notificationService = NotificationService();
    await notificationService.showIncompleteHabitsNotification(incompleteHabits);
    
    debugPrint('Incomplete habits notification shown: ${incompleteHabits.length} habits');
    return true;
  } catch (e, stack) {
    debugPrint('Error in incomplete habits check: $e');
    debugPrint('Stack: $stack');
    return false;
  }
}

// Midnight reset - rebuild widget data for new day
Future<bool> _midnightWidgetReset() async {
  try {
    debugPrint('MIDNIGHT RESET: Starting widget refresh for new day');
    
    // Initialize Hive for background access
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitLogAdapter());
    }
    
    // Open boxes
    if (!Hive.isBoxOpen('habits')) {
      await Hive.openBox<Habit>('habits');
    }
    if (!Hive.isBoxOpen('habitLogs')) {
      await Hive.openBox<HabitLog>('habitLogs');
    }
    
    // Update widget with fresh data for new day
    await WidgetHelper.updateWidgetFromBoxes();
    
    debugPrint('MIDNIGHT RESET: Widget updated successfully for new day');
    return true;
  } catch (e, stack) {
    debugPrint('MIDNIGHT RESET ERROR: $e');
    debugPrint('Stack: $stack');
    return false;
  }
}

class WorkmanagerService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    _isInitialized = true;
    debugPrint('Workmanager initialized ✓');
  }
  
  static Future<void> scheduleIncompleteHabitsTask(int intervalHours) async {
    await initialize();
    
    // Cancel existing task
    await Workmanager().cancelByTag(incompleteHabitsTask);
    
    // Schedule new periodic task
    await Workmanager().registerPeriodicTask(
      incompleteHabitsTask,
      incompleteHabitsTask,
      tag: incompleteHabitsTask,
      frequency: Duration(hours: intervalHours),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
    
    debugPrint('Scheduled incomplete habits task every $intervalHours hours');
  }
  
  static Future<void> scheduleMidnightResetTask() async {
    await initialize();
    
    // Cancel existing task
    await Workmanager().cancelByTag(midnightResetTask);
    
    // Calculate time until next midnight (00:05 to be safe)
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 5);
    final initialDelay = tomorrow.difference(now);
    
    // Schedule periodic task that runs at midnight every day
    await Workmanager().registerPeriodicTask(
      midnightResetTask,
      midnightResetTask,
      tag: midnightResetTask,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
    
    debugPrint('Scheduled midnight reset task starting at ${tomorrow.toIso8601String()}');
  }
  
  static Future<void> cancelMidnightResetTask() async {
    if (!_isInitialized) return;
    await Workmanager().cancelByTag(midnightResetTask);
    debugPrint('Cancelled midnight reset task');
  }
  
  static Future<void> cancelIncompleteHabitsTask() async {
    if (!_isInitialized) return;
    await Workmanager().cancelByTag(incompleteHabitsTask);
    debugPrint('Cancelled incomplete habits task');
  }
  
  static Future<void> cancelAllTasks() async {
    if (!_isInitialized) return;
    await Workmanager().cancelAll();
    debugPrint('Cancelled all Workmanager tasks');
  }
}
