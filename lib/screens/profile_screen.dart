import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notices_provider.dart';
import '../models/notice.dart';
import 'home_screen.dart';
import 'manage_habits_screen.dart';
import 'settings_screen.dart';
import 'rank_celebration_screen.dart';
import 'edit_profile_screen.dart';
import 'weekly_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedTab = 'status';

  @override
  void initState() {
    super.initState();
    _checkRankUp();
  }

  void _checkRankUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitProvider = context.read<HabitProvider>();
      final userProvider = context.read<UserProvider>();
      final noticesProvider = context.read<NoticesProvider>();
      
      final totalCompletions = _calculateTotalCompletions(habitProvider);
      final currentRank = _getCurrentRank(totalCompletions);
      final currentStreak = _calculateCurrentStreak(habitProvider);
      
      // Check for rank achievement
      final rankThreshold = _getRankThreshold(currentRank);
      if (totalCompletions >= rankThreshold) {
        noticesProvider.addRankNotice(currentRank);
      }
      
      // Update best streak
      final prevBest = userProvider.bestStreak;
      if (currentStreak > prevBest) {
        userProvider.setBestStreak(currentStreak);
        if ([7, 14, 30, 60, 100].contains(currentStreak)) {
          noticesProvider.addStreakNotice(currentStreak);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final userProvider = context.watch<UserProvider>();
    final noticesProvider = context.watch<NoticesProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
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
                    onTap: _goBack,
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
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToSettings(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.settings_outlined, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar and name
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB3C6), Color(0xFFFFD6A5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userProvider.genderEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111111),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userProvider.userName.isNotEmpty ? userProvider.userName : 'Your Name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTab('Status', 'status'),
                    ),
                    Expanded(
                      child: _buildTab('Notices', 'notices', 
                        badge: noticesProvider.unreadCount),
                    ),
                  ],
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: _selectedTab == 'status'
                ? _buildStatusTab(habitProvider, userProvider)
                : _buildNoticesTab(noticesProvider),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTab(String label, String value, {int badge = 0}) {
    final isSelected = _selectedTab == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected 
                  ? Colors.white 
                  : (isDark ? const Color(0xFF888888) : const Color(0xFFAAAAAA)),
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4757),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(HabitProvider habitProvider, UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCompletions = _calculateTotalCompletions(habitProvider);
    final currentRank = _getCurrentRank(totalCompletions);
    final nextRank = _getNextRank(currentRank);
    final progressToNext = _getProgressToNextRank(totalCompletions, currentRank);
    final currentStreak = _calculateCurrentStreak(habitProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current streak display
          if (currentStreak > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9F43), Color(0xFFFF6584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9F43).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak Day Streak!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Keep it going!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rank section
          Text(
            'Your Rank',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRankCard('↑', 'Newbie', currentRank == 'Newbie', 
                const Color(0xFFAAAAAA), totalCompletions, 0, 100),
              const SizedBox(width: 8),
              _buildRankCard('↑↑', 'Advanced', currentRank == 'Advanced', 
                const Color(0xFF4CAF50), totalCompletions, 100, 500),
              const SizedBox(width: 8),
              _buildRankCard('↑↑↑', 'Pro', currentRank == 'Pro', 
                const Color(0xFF2196F3), totalCompletions, 500, 999999),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          if (nextRank.isNotEmpty) ...[
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: progressToNext,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalCompletions / ${_getRankThreshold(nextRank)} to $nextRank',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF888888),
                  ),
                ),
                Text(
                  '${(progressToNext * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                '🏆 Maximum rank achieved!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Settings shortcuts
          Text(
            'Quick Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            Icons.bar_chart_outlined,
            'Weekly Report',
            'View and share your weekly habit report',
            _openWeeklyReport,
          ),

          _buildSettingsTile(
            Icons.palette_outlined,
            'Manage Habits',
            'Add, edit or reorder your habits',
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageHabitsScreen()),
            ),
          ),

          _buildSettingsTile(
            Icons.notifications_outlined,
            'Daily Reminder',
            userProvider.reminderEnabled 
              ? 'Enabled at ${userProvider.reminderTime}'
              : 'Disabled',
            () => _navigateToSettings(),
          ),

          _buildSettingsTile(
            Icons.calendar_today_outlined,
            'Week Starts On',
            userProvider.weekStart == 0 ? 'Sunday' : 'Monday',
            () => _navigateToSettings(),
          ),

          const SizedBox(height: 32),

          // Info section
          Text(
            'Your Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoField('Name', userProvider.userName.isNotEmpty 
            ? userProvider.userName 
            : 'Not set'),
          _buildInfoField('Gender', userProvider.gender == 'male' ? 'Male' : 'Female'),
          _buildInfoField('Joined', 'February 2026'),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRankCard(String arrow, String label, bool isActive, Color color, 
    int totalCompletions, int minThreshold, int maxThreshold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAchieved = totalCompletions >= minThreshold;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isActive
                ? color.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isAchieved ? Icons.check_circle : Icons.lock_outline,
              color: isAchieved ? color : const Color(0xFFCCCCCC),
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              arrow,
              style: TextStyle(
                fontSize: 20,
                color: isAchieved ? color : const Color(0xFFCCCCCC),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? color : (isAchieved 
                  ? const Color(0xFF666666) 
                  : const Color(0xFFAAAAAA)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFC8F53C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF111111), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFFAAAAAA), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF888888),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesTab(NoticesProvider noticesProvider) {
    final notices = noticesProvider.notices;
    final userProvider = context.read<UserProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Daily reminder (always shows if enabled)
          if (userProvider.reminderEnabled)
            _buildReminderNoticeCard(userProvider),
          
          // Dynamic notices
          if (notices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notices yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ...notices.map((notice) => _buildDynamicNoticeCard(notice, noticesProvider)),
        ],
      ),
    );
  }

  Widget _buildReminderNoticeCard(UserProvider userProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToSettings(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
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
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: Color(0xFFFF9F43),
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
                    'Don\'t forget your habits today! ${userProvider.reminderTime}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicNoticeCard(Notice notice, NoticesProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    IconData icon;
    Color iconColor;
    
    switch (notice.type) {
      case 'rank_Advanced':
      case 'rank_Pro':
        bgColor = const Color(0xFFE8FFE8);
        icon = Icons.emoji_events_outlined;
        iconColor = const Color(0xFF4CAF50);
        break;
      case 'streak':
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.local_fire_department;
        iconColor = const Color(0xFFFF9F43);
        break;
      case 'complete':
        bgColor = const Color(0xFFE8F4FF);
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF4DABF7);
        break;
      default:
        bgColor = const Color(0xFFF3E8FF);
        icon = Icons.notifications_outlined;
        iconColor = const Color(0xFF845EF7);
    }

    return GestureDetector(
      onTap: () {
        provider.markAsRead(notice.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: !notice.isRead 
            ? Border.all(color: iconColor.withOpacity(0.3), width: 1)
            : null,
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
                color: bgColor.withOpacity(isDark ? 0.3 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    notice.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            if (!notice.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openWeeklyReport() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeklyReportScreen(weekStart: weekStart),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // Helper methods
  int _calculateTotalCompletions(HabitProvider provider) {
    int total = 0;
    for (final habit in provider.habits) {
      total += provider.getTotalCompletions(habit.id);
    }
    return total;
  }

  int _calculateCurrentStreak(HabitProvider provider) {
    int streak = 0;
    DateTime date = DateTime.now();
    
    while (true) {
      final completed = provider.getCompletedCountForDate(date);
      if (completed > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  String _getCurrentRank(int totalCompletions) {
    if (totalCompletions >= 500) return 'Pro';
    if (totalCompletions >= 100) return 'Advanced';
    return 'Newbie';
  }

  String _getNextRank(String currentRank) {
    switch (currentRank) {
      case 'Newbie': return 'Advanced';
      case 'Advanced': return 'Pro';
      case 'Pro': return '';
      default: return '';
    }
  }

  int _getRankThreshold(String rank) {
    switch (rank) {
      case 'Advanced': return 100;
      case 'Pro': return 500;
      default: return 100;
    }
  }

  double _getProgressToNextRank(int totalCompletions, String currentRank) {
    switch (currentRank) {
      case 'Newbie':
        return (totalCompletions / 100).clamp(0.0, 1.0);
      case 'Advanced':
        return ((totalCompletions - 100) / 400).clamp(0.0, 1.0);
      case 'Pro':
        return 1.0;
      default:
        return 0.0;
    }
  }
}
