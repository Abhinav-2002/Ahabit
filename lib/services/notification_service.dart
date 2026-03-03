import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ─── INIT ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('Timezone set to: $tzName');
    } catch (e) {
      debugPrint('Timezone fallback to UTC: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_daily_reminder', 'Daily Reminder',
      description: 'Your daily habit reminder',
      importance: Importance.high,
      playSound: true, enableVibration: true,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_smart_reminders', 'Smart Reminders',
      description: 'Smart incomplete habit reminders',
      importance: Importance.high,
      playSound: true, enableVibration: true,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'streak_protection', 'Streak Protection',
      description: 'Urgent streak danger warnings',
      importance: Importance.max,
      playSound: true, enableVibration: true,
      enableLights: true, ledColor: Color(0xFFFF9F43),
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'weekly_report', 'Weekly Report',
      description: 'Sunday weekly habit report',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_incomplete_reminders', 'Incomplete Habit Reminders',
      description: 'Reminds you of habits not yet completed today',
      importance: Importance.high,
      playSound: true, enableVibration: true,
    ));

    _isInitialized = true;
    debugPrint('NotificationService initialised ✓');
  }

  // ─── PERMISSIONS ───────────────────────────────────────────────────────────

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    debugPrint('Notification permission: $granted');
    final exact = await android?.requestExactAlarmsPermission();
    debugPrint('Exact alarm permission: $exact');

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  /// Next occurrence of the given hour:minute. If it's already past today,
  /// returns tomorrow at that time.
  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  /// Schedule a one-shot exact alarm. No matchDateTimeComponents — we
  /// reschedule fresh on every app open via rescheduleAll().
  Future<void> _scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    Color color = const Color(0xFFFF6B8A),
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: priority,
          icon: '@mipmap/ic_launcher',
          color: color,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('Scheduled #$id "$title" for $when');
  }

  // ─── A) DAILY REMINDER ─────────────────────────────────────────────────────

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String userName,
  }) async {
    await init();
    await _plugin.cancel(0);

    await _scheduleOneShot(
      id: 0,
      title: '⏰ Habit Reminder',
      body: 'Hey $userName! Don\'t forget your habits today 💪',
      when: _nextTime(hour, minute),
      channelId: 'habit_daily_reminder',
      channelName: 'Daily Reminder',
    );
  }

  Future<void> cancelDailyReminder() async => await _plugin.cancel(0);

  // ─── B) SMART REMINDERS (Customizable times) ─────────────────────────────

  Future<void> scheduleSmartReminders({
    required String userName,
    List<Map<String, dynamic>>? customTimes,
  }) async {
    await init();
    // Cancel existing smart reminders (IDs 100-110 for up to 10 reminders)
    for (int i = 100; i <= 110; i++) {
      await _plugin.cancel(i);
    }

    final List<Map<String, dynamic>> schedule;
    
    if (customTimes != null && customTimes.isNotEmpty) {
      // Use custom times provided by user
      schedule = [];
      for (int i = 0; i < customTimes.length; i++) {
        final time = customTimes[i];
        final hour = time['hour'] as int;
        final minute = time['minute'] as int;
        final label = time['label'] as String? ?? _getTimeLabel(hour);
        
        schedule.add({
          'id': 100 + i,
          'h': hour,
          'm': minute,
          't': label,
          'b': _getReminderMessage(userName, i, customTimes.length),
        });
      }
    } else {
      // Default schedule if no custom times provided
      schedule = [
        {'id': 100, 'h': 10, 'm': 0,  't': 'Morning Check ☀️',   'b': 'Hey $userName! Start your habits early today 💪'},
        {'id': 101, 'h': 14, 'm': 0,  't': 'Afternoon Nudge 🕑', 'b': '$userName, some habits are still pending ⚡'},
        {'id': 102, 'h': 18, 'm': 0,  't': 'Evening Reminder 🌆', 'b': 'A few hours left! Complete your habits today 🎯'},
        {'id': 103, 'h': 21, 'm': 0,  't': 'Final Reminder 🌙',  'b': 'Last chance $userName! Complete habits before midnight 🔥'},
      ];
    }

    for (final s in schedule) {
      await _scheduleOneShot(
        id: s['id'] as int,
        title: s['t'] as String,
        body: s['b'] as String,
        when: _nextTime(s['h'] as int, s['m'] as int),
        channelId: 'habit_smart_reminders',
        channelName: 'Smart Reminders',
      );
    }
  }

  String _getTimeLabel(int hour) {
    if (hour < 12) return 'Morning Reminder ☀️';
    if (hour < 17) return 'Afternoon Reminder 🕑';
    if (hour < 20) return 'Evening Reminder 🌆';
    return 'Night Reminder 🌙';
  }

  String _getReminderMessage(String userName, int index, int total) {
    if (index == 0) return 'Hey $userName! Start your habits early today 💪';
    if (index == total - 1) return 'Last chance $userName! Complete habits before midnight 🔥';
    return '$userName, some habits are still pending ⚡';
  }

  Future<void> cancelSmartReminders() async {
    for (int i = 100; i <= 110; i++) {
      await _plugin.cancel(i);
    }
  }

  // ─── C) STREAK PROTECTION (9pm + 10:30pm) ─────────────────────────────────

  Future<void> scheduleStreakProtection({
    required int currentStreak,
    required String userName,
  }) async {
    await init();
    await _plugin.cancel(200);
    await _plugin.cancel(201);

    if (currentStreak < 3) {
      debugPrint('Streak $currentStreak < 3, skipping protection');
      return;
    }

    await _scheduleOneShot(
      id: 200,
      title: '🚨 Streak in Danger!',
      body: 'Your $currentStreak day streak ends at midnight! Complete 1 habit now 🔥',
      when: _nextTime(21, 0),
      channelId: 'streak_protection',
      channelName: 'Streak Protection',
      importance: Importance.max,
      priority: Priority.max,
      color: const Color(0xFFFF9F43),
    );

    await _scheduleOneShot(
      id: 201,
      title: '⏰ Last 90 Minutes!',
      body: 'Don\'t lose your $currentStreak day streak $userName 💪',
      when: _nextTime(22, 30),
      channelId: 'streak_protection',
      channelName: 'Streak Protection',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  Future<void> cancelStreakWarnings() async {
    await _plugin.cancel(200);
    await _plugin.cancel(201);
  }

  // ─── D) WEEKLY REPORT (Sunday 8pm) ────────────────────────────────────────

  Future<void> scheduleWeeklyReport() async {
    await init();
    await _plugin.cancel(300);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    while (scheduled.weekday != DateTime.sunday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _scheduleOneShot(
      id: 300,
      title: '📊 Your Weekly Report is Ready!',
      body: 'See how you did this week. Tap to view your habit report 🏆',
      when: scheduled,
      channelId: 'weekly_report',
      channelName: 'Weekly Report',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  // ─── RESCHEDULE ALL ────────────────────────────────────────────────────────
  // Called on every app open + resume. Reschedules all one-shot alarms.

  Future<void> rescheduleAll() async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'there';

    // A) Daily reminder
    final reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
    if (reminderEnabled) {
      final timeStr = prefs.getString('reminder_time') ?? '08:00';
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await scheduleDailyReminder(hour: hour, minute: minute, userName: userName);
    }

    // B) Smart reminders
    final smartEnabled = prefs.getBool('smart_reminders_enabled') ?? false;
    if (smartEnabled) {
      final customTimesJson = prefs.getStringList('smart_reminder_times');
      List<Map<String, dynamic>>? customTimes;
      if (customTimesJson != null && customTimesJson.isNotEmpty) {
        customTimes = customTimesJson.map((json) {
          final parts = json.split(':');
          return {
            'hour': int.tryParse(parts[0]) ?? 10,
            'minute': int.tryParse(parts[1]) ?? 0,
            'label': parts.length > 2 ? parts[2] : null,
          };
        }).toList();
      }
      await scheduleSmartReminders(userName: userName, customTimes: customTimes);
    }

    // C) Streak protection
    final streak = await _calculateStreakFromHive();
    await scheduleStreakProtection(currentStreak: streak, userName: userName);

    // D) Weekly report
    await scheduleWeeklyReport();

    debugPrint('All notifications rescheduled ✓');
  }

  // ─── E) INCOMPLETE HABIT REMINDERS ─────────────────────────────────────────

  Future<void> showIncompleteHabitsNotification(List<String> incompleteHabits) async {
    await init();
    
    if (incompleteHabits.isEmpty) return;
    
    final count = incompleteHabits.length;
    final habitList = incompleteHabits.take(3).join(', ');
    final moreText = count > 3 ? ' and ${count - 3} more' : '';
    
    final title = '📝 You have $count habit${count == 1 ? '' : 's'} left!';
    final body = '$habitList$moreText - Complete them today 💪';
    
    await _plugin.show(
      500,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_incomplete_reminders',
          'Incomplete Habit Reminders',
          channelDescription: 'Reminds you of habits not yet completed today',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF6584),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
    debugPrint('Shown incomplete habits notification: $count habits');
  }

  Future<void> cancelIncompleteHabitsNotification() async {
    await _plugin.cancel(500);
  }

  // ─── CANCEL ALL ────────────────────────────────────────────────────────────

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  // ─── INTERNAL ──────────────────────────────────────────────────────────────

  Future<int> _calculateStreakFromHive() async {
    try {
      if (!Hive.isBoxOpen('habitLogs')) {
        await Hive.openBox<HabitLog>('habitLogs');
      }
      final logsBox = Hive.box<HabitLog>('habitLogs');

      int streak = 0;
      var check = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

      while (true) {
        final anyDone = logsBox.values.any((log) {
          final d = DateTime(log.date.year, log.date.month, log.date.day);
          return d.isAtSameMomentAs(check) &&
              log.isPunched &&
              !log.habitId.startsWith('FREEZE_');
        });
        final isFrozen = logsBox.values.any(
          (l) => l.habitId ==
              'FREEZE_${check.toIso8601String().substring(0, 10)}',
        );
        if (anyDone || isFrozen) {
          streak++;
          check = check.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }
}
