import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../data/habit_templates.dart';
import '../services/widget_helper.dart';

class TemplatePacksScreen extends StatefulWidget {
  const TemplatePacksScreen({super.key});

  @override
  State<TemplatePacksScreen> createState() => _TemplatePacksScreenState();
}

class _TemplatePacksScreenState extends State<TemplatePacksScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadInstalledPacks() async {
    // No longer needed
  }

  Future<void> _installPack(TemplatePack pack) async {
    final habitProvider = context.read<HabitProvider>();
    final existingHabits = habitProvider.habits;
    final existingCount = existingHabits.length;
    
    int added = 0;
    int skipped = 0;

    for (int i = 0; i < pack.habits.length; i++) {
      final template = pack.habits[i];

      // Check by name — skip if already exists
      final exists = existingHabits.any(
        (h) => h.name.toLowerCase().trim() == template.name.toLowerCase().trim() && !h.isHidden
      );
      
      if (exists) {
        skipped++;
        continue;
      }

      final colorValue = habitColors[(existingCount + added) % habitColors.length].value;

      await habitProvider.addHabit(
        template.name,
        template.icon,
        colorValue,
        frequency: template.frequency,
      );
      added++;
      
      // Small delay to ensure unique IDs visually
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Update widgets
    await WidgetHelper.updateWidget(habitProvider);

    if (mounted) {
      final message = skipped == 0
        ? '${pack.emoji} $added habits added!'
        : added == 0
          ? '${pack.emoji} All habits already in your list'
          : '${pack.emoji} $added added, $skipped already existed';
          
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: added > 0
            ? pack.primaryColor.withOpacity(0.9)
            : Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Habit Templates',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B8A),
                    Color(0xFFFF9F43),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Start! 🚀',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a pack and install all habits in 1 tap',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text('📦', style: TextStyle(fontSize: 40)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Choose a Pack',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),

            // Pack cards
            ...habitTemplatePacks.map((pack) {
              return _buildPackCard(pack);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard(TemplatePack pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pack header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  pack.primaryColor,
                  pack.secondaryColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Text(pack.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        pack.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Habits preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...pack.habits.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(h.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pack.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              'Daily',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),

                const SizedBox(height: 12),

                // Install button
                GestureDetector(
                  onTap: () => _installPack(pack),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '+ Install ${pack.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallConfirm(TemplatePack pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pack.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Install ${pack.name}?',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Habits that already exist in your list '
              'will be skipped automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _installPack(pack);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Install Now 🚀',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
