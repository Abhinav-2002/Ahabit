import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  static const String _nameKey = 'user_name';
  static const String _genderKey = 'user_gender';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _weekStartKey = 'week_start';
  static const String _bestStreakKey = 'best_streak';
  static const String _onboardingCompleteKey = 'onboarding_done';
  static const String _smartRemindersEnabledKey = 'smart_reminders_enabled';
  static const String _smartReminderTimesKey = 'smart_reminder_times';
  static const String _incompleteRemindersEnabledKey = 'incomplete_reminders_enabled';
  static const String _incompleteReminderIntervalKey = 'incomplete_reminder_interval';

  String _userName = '';
  String _gender = 'female';
  bool _reminderEnabled = true;
  String _reminderTime = '08:00';
  int _weekStart = 1; // 0 = Sunday, 1 = Monday
  int _bestStreak = 0;
  bool _onboardingComplete = false;
  bool _smartRemindersEnabled = false;
  List<Map<String, dynamic>> _smartReminderTimes = [];
  bool _incompleteRemindersEnabled = false;
  int _incompleteReminderInterval = 2;

  // Getters
  String get userName => _userName;
  String get gender => _gender;
  bool get reminderEnabled => _reminderEnabled;
  String get reminderTime => _reminderTime;
  int get weekStart => _weekStart;
  int get bestStreak => _bestStreak;
  bool get isOnboardingComplete => _onboardingComplete;
  bool get smartRemindersEnabled => _smartRemindersEnabled;
  List<Map<String, dynamic>> get smartReminderTimes => _smartReminderTimes;
  bool get incompleteRemindersEnabled => _incompleteRemindersEnabled;
  int get incompleteReminderInterval => _incompleteReminderInterval;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_nameKey) ?? '';
    _gender = prefs.getString(_genderKey) ?? 'female';
    _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? true;
    _reminderTime = prefs.getString(_reminderTimeKey) ?? '08:00';
    _weekStart = prefs.getInt(_weekStartKey) ?? 1;
    _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    _onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _smartRemindersEnabled = prefs.getBool(_smartRemindersEnabledKey) ?? false;
    _smartReminderTimes = _loadSmartReminderTimes(prefs);
    _incompleteRemindersEnabled = prefs.getBool(_incompleteRemindersEnabledKey) ?? false;
    _incompleteReminderInterval = prefs.getInt(_incompleteReminderIntervalKey) ?? 2;
    notifyListeners();
  }

  // Name
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name;
    await prefs.setString(_nameKey, name);
    notifyListeners();
  }

  // Gender
  Future<void> setGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    _gender = gender;
    await prefs.setString(_genderKey, gender);
    notifyListeners();
  }

  // Reminder enabled
  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _reminderEnabled = enabled;
    await prefs.setBool(_reminderEnabledKey, enabled);
    notifyListeners();
  }

  // Reminder time
  Future<void> setReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    _reminderTime = time;
    await prefs.setString(_reminderTimeKey, time);
    notifyListeners();
  }

  // Week start
  Future<void> setWeekStart(int weekStart) async {
    final prefs = await SharedPreferences.getInstance();
    _weekStart = weekStart;
    await prefs.setInt(_weekStartKey, weekStart);
    notifyListeners();
  }

  // Best streak
  Future<void> setBestStreak(int streak) async {
    if (streak > _bestStreak) {
      final prefs = await SharedPreferences.getInstance();
      _bestStreak = streak;
      await prefs.setInt(_bestStreakKey, streak);
      notifyListeners();
    }
  }

  // Onboarding complete
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = true;
    await prefs.setBool(_onboardingCompleteKey, true);
    notifyListeners();
  }

  // Smart reminders
  Future<void> setSmartRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _smartRemindersEnabled = enabled;
    await prefs.setBool(_smartRemindersEnabledKey, enabled);
    notifyListeners();
  }

  // Smart reminder times
  Future<void> setSmartReminderTimes(List<Map<String, dynamic>> times) async {
    final prefs = await SharedPreferences.getInstance();
    _smartReminderTimes = times;
    final timeStrings = times.map((t) {
      final hour = t['hour'] as int;
      final minute = t['minute'] as int;
      final label = t['label'] as String?;
      if (label != null && label.isNotEmpty) {
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:$label';
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }).toList();
    await prefs.setStringList(_smartReminderTimesKey, timeStrings);
    notifyListeners();
  }

  // Incomplete habit reminders
  Future<void> setIncompleteRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _incompleteRemindersEnabled = enabled;
    await prefs.setBool(_incompleteRemindersEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setIncompleteReminderInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    _incompleteReminderInterval = hours;
    await prefs.setInt(_incompleteReminderIntervalKey, hours);
    notifyListeners();
  }

  List<Map<String, dynamic>> _loadSmartReminderTimes(SharedPreferences prefs) {
    final timeStrings = prefs.getStringList(_smartReminderTimesKey);
    if (timeStrings == null || timeStrings.isEmpty) {
      // Return default times if none saved
      return [
        {'hour': 10, 'minute': 0, 'label': 'Morning Check ☀️'},
        {'hour': 14, 'minute': 0, 'label': 'Afternoon Nudge 🕑'},
        {'hour': 18, 'minute': 0, 'label': 'Evening Reminder 🌆'},
        {'hour': 21, 'minute': 0, 'label': 'Final Reminder 🌙'},
      ];
    }
    return timeStrings.map((str) {
      final parts = str.split(':');
      return {
        'hour': int.tryParse(parts[0]) ?? 10,
        'minute': int.tryParse(parts[1]) ?? 0,
        'label': parts.length > 2 ? parts.sublist(2).join(':') : null,
      };
    }).toList();
  }

  // Widget added tracking
  Future<void> setWidgetAdded(bool added) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_added', added);
  }

  Future<bool> isWidgetAdded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('widget_added') ?? false;
  }

  // Update user (name and gender together)
  void updateUser(String name, String gender) {
    _userName = name;
    _gender = gender.toLowerCase();
    notifyListeners();
  }

  // Get greeting name
  String get greetingName => _userName.isNotEmpty ? _userName : 'Habit Tracker';

  // Get emoji based on gender
  String get genderEmoji => _gender == 'male' ? '🧔' : '👩';
}
