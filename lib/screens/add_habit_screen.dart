import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../data/habit_templates.dart';
import 'template_packs_screen.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedEmoji = '🏃';
  int _selectedColor = 0xFFFF6584;
  String _frequency = 'daily';

  final List<String> _emojis = [
    '💀', '👽', '🐎', '🍒', '👟', '🚲', '🍇', '🏀',
    '⛸️', '🏌️', '🎯', '♟️', '✏️', '🚀', '⚽', '📚',
    '💧', '🌙', '☀️', '🧘', '💪', '🔥', '🎸', '🎨',
    '💊', '🥗', '🚫', '🛌', '💰', '🎮', '💻', '📱',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _selectedEmoji = widget.habit!.icon;
      _selectedColor = widget.habit!.colorValue;
      _frequency = widget.habit!.frequency;
      if (widget.habit!.description != null) {
        _descriptionController.text = widget.habit!.description!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.habit != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isEditing ? 'Edit Habit' : 'New Habit',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          isEditing ? 'Update your habit' : 'Create a new habit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const TemplatePacksScreen(),
                        )),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFF6B8A).withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Text('📦', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Browse Templates',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      )),
                                    Text('Install a habit pack in 1 tap',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFFAAAAAA) : Colors.grey,
                                      )),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                size: 14, color: isDark ? const Color(0xFFAAAAAA) : Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    
                    // Title
                    Text(
                      'Habit Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name input
                    Container(
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
                      child: TextField(
                        controller: _nameController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLength: 50,
                        decoration: InputDecoration(
                          hintText: 'e.g., Drink Water',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFAAAAAA),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Description (Optional)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                      child: TextField(
                        controller: _descriptionController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        maxLength: 120,
                        decoration: InputDecoration(
                          hintText: 'e.g., Drink 8 glasses daily',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFAAAAAA),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                    ),
                    // Frequency
                    Text(
                      'Frequency',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _frequency,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'custom', child: Text('Custom days')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _frequency = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Icon selection
                    Text(
                      'Select Icon',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Emoji grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = _emojis[index];
                        final isSelected = _selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = emoji),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                ? Border.all(color: const Color(0xFF111111), width: 2.5)
                                : null,
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                    ? Colors.black.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.06),
                                  blurRadius: isSelected ? 16 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Color selection
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Color grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: habitColors.map((colorObj) {
                        final color = colorObj.value;
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: isSelected
                                ? Border.all(color: const Color(0xFF111111), width: 3)
                                : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(color).withOpacity(0.4),
                                  blurRadius: isSelected ? 16 : 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    // Save button
                    GestureDetector(
                      onTap: _saveHabit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEditing ? 'Update Habit' : 'Create Habit',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showValidationError('Please enter a habit name');
      return;
    }

    if (name.length > 50) {
      _showValidationError('Habit name must be 50 characters or less');
      return;
    }

    if (description.length > 120) {
      _showValidationError('Description must be 120 characters or less');
      return;
    }

    HapticFeedback.lightImpact();
    
    // Find color index
    int colorIndex = 0;
    for (int i = 0; i < habitColors.length; i++) {
      if (habitColors[i].value == _selectedColor) {
        colorIndex = i;
        break;
      }
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'emoji': _selectedEmoji,
      'colorValue': _selectedColor,
      'colorIndex': colorIndex,
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'frequency': _frequency,
    });
  }
}
