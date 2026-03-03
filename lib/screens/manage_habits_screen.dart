import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../services/widget_helper.dart';
import 'add_habit_screen.dart';

class ManageHabitsScreen extends StatefulWidget {
  const ManageHabitsScreen({super.key});

  @override
  State<ManageHabitsScreen> createState() => _ManageHabitsScreenState();
}

class _ManageHabitsScreenState extends State<ManageHabitsScreen> {
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
                    onTap: () => Navigator.of(context).pop(),
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
                      'Manage Habits',
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

            // Add new button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: GestureDetector(
                onTap: () => _addNewHabit(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F53C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8F53C).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Color(0xFF111111)),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Habit',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Habits list
            Expanded(
              child: habits.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: habits.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = habits.removeAt(oldIndex);
                        habits.insert(newIndex, item);
                      });
                      habitProvider.reorderHabits(habits);
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(16),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return _buildHabitCard(habit, index);
                    },
                  ),
            ),
          ],
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
            Icons.format_list_bulleted,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add New Habit" to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: ValueKey(habit.id),
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(habit.colorValue).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          habit.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: habit.isHidden ? TextDecoration.lineThrough : null,
            color: habit.isHidden ? const Color(0xFFAAAAAA) : null,
          ),
        ),
        subtitle: habit.isHidden
          ? const Text('Hidden', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)))
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hide/show button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<HabitProvider>().toggleHabitVisibility(habit.id);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: habit.isHidden
                    ? const Color(0xFF4CAF50).withOpacity(0.15)
                    : const Color(0xFFFF6584).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  habit.isHidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: habit.isHidden ? const Color(0xFF4CAF50) : const Color(0xFFFF6584),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit button
            GestureDetector(
              onTap: () => _editHabit(habit),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4DABF7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, size: 16, color: Color(0xFF4DABF7)),
              ),
            ),
            const SizedBox(width: 8),
            // Reorder handle
            GestureDetector(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.drag_handle, size: 16, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewHabit() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
    );

    if (result != null && mounted) {
      await context.read<HabitProvider>().addHabit(
        result['name'],
        result['emoji'] ?? result['icon'] ?? '📌',
        result['colorValue'] ?? 0xFFFF6584,
        frequency: result['frequency'] ?? 'daily',
      );
      WidgetHelper.triggerWidgetUpdate();
    }
  }

  void _editHabit(Habit habit) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddHabitScreen(habit: habit)),
    );

    if (result != null && mounted) {
      habit.name = result['name'];
      habit.icon = result['emoji'] ?? result['icon'] ?? habit.icon;
      habit.colorValue = result['colorValue'] ?? habit.colorValue;
      habit.frequency = result['frequency'] ?? habit.frequency;
      await context.read<HabitProvider>().updateHabit(habit);
      WidgetHelper.triggerWidgetUpdate();
    }
  }
}
