import '../models/habit_log.dart';

/// Abstract repository interface for HabitLog operations
abstract class HabitLogRepository {
  List<HabitLog> getAllLogs();
  List<HabitLog> getLogsForHabit(String habitId);
  HabitLog? getLogForDate(String habitId, DateTime date);
  Future<void> saveLog(HabitLog log);
  Future<void> deleteLog(String id);
  Future<void> addLog(HabitLog log);
  Future<int> clearAllLogs();
}

/// Stub implementation for testing (no-op)
class StubHabitLogRepository implements HabitLogRepository {
  @override
  List<HabitLog> getAllLogs() => [];
  
  @override
  List<HabitLog> getLogsForHabit(String habitId) => [];
  
  @override
  HabitLog? getLogForDate(String habitId, DateTime date) => null;
  
  @override
  Future<void> saveLog(HabitLog log) async {}
  
  @override
  Future<void> deleteLog(String id) async {}
  
  @override
  Future<void> addLog(HabitLog log) async {}
  
  @override
  Future<int> clearAllLogs() async => 0;
}
