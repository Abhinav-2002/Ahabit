import '../models/habit.dart';

/// Abstract repository interface for Habit operations
abstract class HabitRepository {
  List<Habit> getAllHabits();
  List<Habit> getVisibleHabits();
  Habit? getHabitById(String id);
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
  Future<void> updateHabit(Habit habit);
}

/// Stub implementation for testing (no-op)
class StubHabitRepository implements HabitRepository {
  @override
  List<Habit> getAllHabits() => [];
  
  @override
  List<Habit> getVisibleHabits() => [];
  
  @override
  Habit? getHabitById(String id) => null;
  
  @override
  Future<void> saveHabit(Habit habit) async {}
  
  @override
  Future<void> deleteHabit(String id) async {}
  
  @override
  Future<void> updateHabit(Habit habit) async {}
}
