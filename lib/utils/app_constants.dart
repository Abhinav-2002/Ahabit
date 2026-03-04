/// Central registry for magic strings used across multiple files.
/// Import and reference these instead of hardcoding literals.
class AppConstants {
  AppConstants._();

  // ── Hive box names ─────────────────────────────────────────────────────────
  static const String habitsBox    = 'habits';
  static const String habitLogsBox = 'habitLogs';
  static const String noticesBox   = 'notices';
  static const String settingsBox  = 'settings';

  // ── SharedPreferences: widget data ─────────────────────────────────────────
  // Flutter shared_preferences plugin stores keys with the 'flutter.' prefix
  // on Android (FlutterSharedPreferences file). Dart side uses the bare key;
  // Kotlin side reads the 'flutter.<key>' form.
  static const String widgetHabitsJson     = 'widget.habits_json';
  static const String widgetEmptyMessage   = 'widget.empty_message';
  static const String widgetStreak         = 'widget.streak';
  static const String widgetDoneCount      = 'widget.done_count';
  static const String widgetTotalCount     = 'widget.total_count';
  static const String widgetCompletionPct  = 'widget.completion_pct';
  static const String widgetDateStr        = 'widget.date_str';
  static const String widgetPendingToggles = 'widget.pending_toggles';

  // ── SharedPreferences: app settings ────────────────────────────────────────
  static const String onboardingDoneKey            = 'onboarding_done';
  static const String isFirstTimeKey               = 'isFirstTime';
  static const String incompleteRemindersEnabledKey = 'incomplete_reminders_enabled';
  static const String incompleteReminderIntervalKey = 'incomplete_reminder_interval';

  // ── Workmanager task identifiers ────────────────────────────────────────────
  static const String taskIncompleteHabits = 'incomplete_habits_check';
  static const String taskMidnightReset    = 'midnight_widget_reset';
  static const String taskWidgetSync       = 'widget_sync';

  // ── Android widget names (must match Kotlin class names) ──────────────────
  static const String androidWidgetMedium = 'HabitWidgetMediumProvider';
  static const String androidWidgetSmall  = 'HabitWidgetSmallProvider';
  static const String iosWidget           = 'HabitWidget';
  static const String appGroupId          = 'group.com.habitpunch.app';
}
