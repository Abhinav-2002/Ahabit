import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../services/workmanager_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    final userProvider = context.read<UserProvider>();
    _nameController.text = userProvider.userName;
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    setState(() => _notificationsInitialized = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();

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
                      'Settings',
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reminders Section
                    _buildSectionTitle('Reminders'),
                    const SizedBox(height: 12),
                    _buildReminderCard(userProvider),
                    
                    const SizedBox(height: 12),
                    
                    // Smart Reminders toggle
                    _buildSmartRemindersCard(userProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Week Start Section
                    _buildSectionTitle('Start of Week'),
                    const SizedBox(height: 12),
                    _buildWeekStartCard(userProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Your Information Section
                    _buildSectionTitle('Your Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(userProvider),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildReminderCard(UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeParts = userProvider.reminderTime.split(':');
    final timeText = '${timeParts[0]}:${timeParts[1]}';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Enable/Disable toggle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6584).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFFF6584),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userProvider.reminderEnabled ? 'Enabled' : 'Disabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: userProvider.reminderEnabled,
                onChanged: (value) async {
                  HapticFeedback.lightImpact();
                  await userProvider.setReminderEnabled(value);
                  if (value && _notificationsInitialized) {
                    final name = userProvider.userName.isNotEmpty 
                      ? userProvider.userName 
                      : 'there';
                    final timeParts = userProvider.reminderTime.split(':');
                    await _notificationService.scheduleDailyReminder(
                      hour: int.parse(timeParts[0]),
                      minute: int.parse(timeParts[1]),
                      userName: name,
                    );
                  } else if (!value) {
                    await _notificationService.cancelAllReminders();
                  }
                },
                activeColor: const Color(0xFFC8F53C),
              ),
            ],
          ),
          
          if (userProvider.reminderEnabled) ...[
            const Divider(height: 24),
            // Time picker
            GestureDetector(
              onTap: () => _showTimePicker(userProvider),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DABF7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color(0xFF4DABF7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Time',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekStartCard(UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week Starts On',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userProvider.weekStart == 0 ? 'Sunday' : 'Monday',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildWeekOption('Sun', 0, userProvider),
              const SizedBox(width: 8),
              _buildWeekOption('Mon', 1, userProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekOption(String label, int value, UserProvider userProvider) {
    final isSelected = userProvider.weekStart == value;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        userProvider.setWeekStart(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Name field
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF845EF7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF845EF7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                    border: InputBorder.none,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final newName = _nameController.text.trim();
                        if (newName.isNotEmpty) {
                          userProvider.setUserName(newName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name saved!')),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8F53C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Gender display
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F43).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  userProvider.genderEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userProvider.gender == 'male' ? 'Male' : 'Female',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRemindersCard(UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF845EF7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFF845EF7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Reminds you about incomplete habits throughout the day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: userProvider.smartRemindersEnabled,
                onChanged: (value) async {
                  HapticFeedback.lightImpact();
                  await userProvider.setSmartRemindersEnabled(value);
                  if (value && _notificationsInitialized) {
                    final name = userProvider.userName.isNotEmpty
                        ? userProvider.userName
                        : 'there';
                    await _notificationService.scheduleSmartReminders(
                      userName: name,
                      customTimes: userProvider.smartReminderTimes,
                    );
                  } else if (!value) {
                    await _notificationService.cancelSmartReminders();
                  }
                },
                activeColor: const Color(0xFFC8F53C),
              ),
            ],
          ),
          if (userProvider.smartRemindersEnabled) ...[
            const Divider(height: 24),
            // Display current reminder times
            ...userProvider.smartReminderTimes.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              final hour = time['hour'] as int;
              final minute = time['minute'] as int;
              final label = time['label'] as String? ?? 'Reminder ${index + 1}';
              final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _showSmartReminderTimePicker(userProvider, index),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF845EF7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF845EF7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.access_time, size: 16, color: Color(0xFFAAAAAA)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeSmartReminderTime(userProvider, index),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Add new reminder button
            if (userProvider.smartReminderTimes.length < 6)
              GestureDetector(
                onTap: () => _addSmartReminderTime(userProvider),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF845EF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF845EF7).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 16, color: Color(0xFF845EF7)),
                      const SizedBox(width: 8),
                      Text(
                        'Add Reminder Time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF845EF7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // INCOMPLETE HABITS SECTION
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.repeat_outlined,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeat reminders for incomplete habits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userProvider.incompleteRemindersEnabled 
                          ? 'Every ${userProvider.incompleteReminderInterval} hour${userProvider.incompleteReminderInterval == 1 ? '' : 's'}'
                          : 'Disabled',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: userProvider.incompleteRemindersEnabled,
                  onChanged: (value) async {
                    HapticFeedback.lightImpact();
                    await userProvider.setIncompleteRemindersEnabled(value);
                    if (value) {
                      await WorkmanagerService.scheduleIncompleteHabitsTask(
                        userProvider.incompleteReminderInterval,
                      );
                    } else {
                      await WorkmanagerService.cancelIncompleteHabitsTask();
                    }
                  },
                  activeColor: const Color(0xFFC8F53C),
                ),
              ],
            ),
            if (userProvider.incompleteRemindersEnabled) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SizedBox(width: 52),
                  Text(
                    'Check every:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                  _buildIntervalChip(1, userProvider),
                  _buildIntervalChip(2, userProvider),
                  _buildIntervalChip(3, userProvider),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildIntervalChip(int hours, UserProvider userProvider) {
    final isSelected = userProvider.incompleteReminderInterval == hours;
    
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await userProvider.setIncompleteReminderInterval(hours);
        if (userProvider.incompleteRemindersEnabled) {
          await WorkmanagerService.scheduleIncompleteHabitsTask(hours);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$hours hr${hours == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(UserProvider userProvider) async {
    final timeParts = userProvider.reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final timeString = 
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      await userProvider.setReminderTime(timeString);
      
      if (userProvider.reminderEnabled && _notificationsInitialized) {
        final name = userProvider.userName.isNotEmpty 
          ? userProvider.userName 
          : 'there';
        await _notificationService.scheduleDailyReminder(
          hour: pickedTime.hour,
          minute: pickedTime.minute,
          userName: name,
        );
      }
    }
  }

  Future<void> _showSmartReminderTimePicker(UserProvider userProvider, int index) async {
    final currentTime = userProvider.smartReminderTimes[index];
    final initialTime = TimeOfDay(
      hour: currentTime['hour'] as int,
      minute: currentTime['minute'] as int,
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final updatedTimes = List<Map<String, dynamic>>.from(userProvider.smartReminderTimes);
      updatedTimes[index] = {
        ...updatedTimes[index],
        'hour': pickedTime.hour,
        'minute': pickedTime.minute,
      };
      await userProvider.setSmartReminderTimes(updatedTimes);
      
      // Reschedule notifications
      if (userProvider.smartRemindersEnabled && _notificationsInitialized) {
        final name = userProvider.userName.isNotEmpty
            ? userProvider.userName
            : 'there';
        await _notificationService.scheduleSmartReminders(
          userName: name,
          customTimes: updatedTimes,
        );
      }
    }
  }

  Future<void> _addSmartReminderTime(UserProvider userProvider) async {
    final now = TimeOfDay.now();
    final newTime = {
      'hour': now.hour,
      'minute': now.minute,
      'label': 'Custom Reminder ⏰',
    };
    
    final updatedTimes = List<Map<String, dynamic>>.from(userProvider.smartReminderTimes);
    updatedTimes.add(newTime);
    await userProvider.setSmartReminderTimes(updatedTimes);
    
    // Reschedule notifications
    if (userProvider.smartRemindersEnabled && _notificationsInitialized) {
      final name = userProvider.userName.isNotEmpty
          ? userProvider.userName
          : 'there';
      await _notificationService.scheduleSmartReminders(
        userName: name,
        customTimes: updatedTimes,
      );
    }
  }

  Future<void> _removeSmartReminderTime(UserProvider userProvider, int index) async {
    HapticFeedback.lightImpact();
    final updatedTimes = List<Map<String, dynamic>>.from(userProvider.smartReminderTimes);
    updatedTimes.removeAt(index);
    await userProvider.setSmartReminderTimes(updatedTimes);
    
    // Reschedule notifications
    if (userProvider.smartRemindersEnabled && _notificationsInitialized) {
      final name = userProvider.userName.isNotEmpty
          ? userProvider.userName
          : 'there';
      await _notificationService.scheduleSmartReminders(
        userName: name,
        customTimes: updatedTimes,
      );
    }
  }
}
