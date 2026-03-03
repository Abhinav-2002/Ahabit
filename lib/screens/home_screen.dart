import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notices_provider.dart';
import '../widgets/calendar_modal.dart';
import 'manage_habits_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';
import '../widgets/activity_rings.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/habit_list_item.dart';
import '../services/notification_service.dart';
import '../services/widget_helper.dart';
import 'weekly_report_screen.dart';
import 'template_packs_screen.dart';
import 'focus_screen.dart';
import '../utils/habit_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showWidgetCard = true;
  bool _showFocusTip = true;
  bool _isCompactMode = false; // NEW: Compact view mode
  DateTime _selectedDate = DateTime.now();
  // Strikethrough animation controllers
  Map<String, AnimationController> _strikeControllers = {};
  Map<String, Animation<double>> _strikeAnimations = {};
  Set<String> _completedHabits = {};

  bool get _isViewingToday => _isSameDay(_selectedDate, DateTime.now());

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  Future<void> _loadCompactModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactMode = prefs.getBool('compact_mode_enabled') ?? false;
    });
  }

  Future<void> _toggleCompactMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactMode = !_isCompactMode;
    });
    await prefs.setBool('compact_mode_enabled', _isCompactMode);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCompactModePreference(); // NEW: Load compact mode preference
    _checkWidgetCard();
    _checkFocusTip();
    _loadDoneStates();
    _rescheduleSmartReminders();
    _checkWeeklyReport();
    _checkShowTemplates();

    // Listen to Hive box changes for auto widget update
    Hive.box<Habit>('habits').listenable().addListener(_onDataChanged);
    Hive.box<HabitLog>('habitLogs').listenable().addListener(_onDataChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sync pending widget toggles after context is ready
      _syncPendingWidgetToggles();
      await WidgetHelper.forceWidgetUpdate();
      await NotificationService().rescheduleAll();
    });
  }

  void _onDataChanged() {
    WidgetHelper.triggerWidgetUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetHelper.triggerWidgetUpdate();
      setState(() {});
    }
  }

  void _checkShowTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('templates_shown') ?? false;
    if (!shown) {
      await prefs.setBool('templates_shown', true);
      // Small delay so home screen loads first
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TemplatePacksScreen(),
          ));
        }
      });
    }
  }

  Future<void> _checkWeeklyReport() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final isSunday = now.weekday == DateTime.sunday;
    final lastShown = prefs.getString('last_weekly_report_shown') ?? '';
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (isSunday && lastShown != todayStr && now.hour >= 20) {
      await prefs.setString('last_weekly_report_shown', todayStr);
      // Navigate to report after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final weekStart = now.subtract(const Duration(days: 6));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WeeklyReportScreen(weekStart: weekStart),
            ),
          );
        }
      });
    }
  }

  Future<void> _rescheduleSmartReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final smartEnabled = prefs.getBool('smart_reminders_enabled') ?? false;
    final userName = prefs.getString('user_name') ?? 'there';
    
    if (smartEnabled) {
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.scheduleSmartReminders(userName: userName);
    }
  }

  void _syncPendingWidgetToggles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('widget.pending_toggles');
      if (pending == null || pending == '[]') return;

      // Clear pending immediately to prevent double
      await prefs.remove('widget.pending_toggles');

      final provider = context.read<HabitProvider>();
      final List decoded = jsonDecode(pending);

      for (final habitId in decoded) {
        // Toggle this habit in Hive
        await provider.toggleHabitById(habitId as String);
      }

      debugPrint('Synced ${decoded.length} widget toggles');
      
      // Update widget after syncing
      await WidgetHelper.updateWidgetFromBoxes();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

@override
void dispose() {
  Hive.box<Habit>('habits').listenable().removeListener(_onDataChanged);
  Hive.box<HabitLog>('habitLogs').listenable().removeListener(_onDataChanged);
  WidgetsBinding.instance.removeObserver(this);
  for (final controller in _strikeControllers.values) {
    controller.dispose();
  }
  super.dispose();
}

  void _initStrikeAnimation(String habitId) {
    if (_strikeControllers.containsKey(habitId)) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    _strikeControllers[habitId] = controller;
    _strikeAnimations[habitId] = animation;
  }

  void _triggerStrikeAnimation(String habitId) {
    final controller = _strikeControllers[habitId];
    if (controller != null && !controller.isCompleted) {
      controller.forward();
    }
  }

  void _reverseStrikeAnimation(String habitId) {
    final controller = _strikeControllers[habitId];
    if (controller != null) {
      controller.reverse();
    }
  }

  void _loadDoneStates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HabitProvider>();
      final habits = provider.visibleHabits;
      final today = DateTime.now();

      for (final habit in habits) {
        _initStrikeAnimation(habit.id);
        final isCompleted = provider.isHabitCompletedToday(habit.id);
        if (isCompleted) {
          // Already done — jump to end without animation
          _strikeControllers[habit.id]?.value = 1.0;
          _completedHabits.add(habit.id);
        }
      }
    });
  }

  void _onHabitDone(String habitId) {
    if (!_completedHabits.contains(habitId)) {
      _triggerStrikeAnimation(habitId);
      _completedHabits.add(habitId);
    }
  }

  void _onHabitUndone(String habitId) {
    if (_completedHabits.contains(habitId)) {
      _reverseStrikeAnimation(habitId);
      _completedHabits.remove(habitId);
    }
  }

  void _onDateSelected(DateTime date) {
    final now = DateTime.now();
    // Block future dates
    if (date.isAfter(DateTime(now.year, now.month, now.day))) return;
    
    setState(() {
      if (_isSameDay(date, _selectedDate)) {
        // Deselect = go back to today
        _selectedDate = DateTime.now();
      } else {
        _selectedDate = date;
      }
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _checkWidgetCard() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetAdded = prefs.getBool('widget_added') ?? false;
    setState(() {
      _showWidgetCard = !widgetAdded;
    });
  }

  Future<void> _checkFocusTip() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('focus_tip_dismissed') ?? false;
    if (mounted) {
      setState(() => _showFocusTip = !dismissed);
    }
  }

  Future<void> _dismissFocusTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focus_tip_dismissed', true);
    setState(() => _showFocusTip = false);
  }

  Future<void> _hideWidgetCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_added', true);
    setState(() {
      _showWidgetCard = false;
    });
  }

  void _showAddWidgetDialog() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add to Home Screen', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          isAndroid
            ? 'To add widget:\n\n1. Long press your home screen\n2. Tap Widgets\n3. Find Habit Tracker\n4. Drag it to your home screen'
            : 'To add widget:\n\n1. Long press your home screen\n2. Tap + in top corner\n3. Search Habit Tracker\n4. Choose size and tap Add Widget',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _hideWidgetCard();
            },
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitProvider = context.watch<HabitProvider>();
    final userProvider = context.watch<UserProvider>();
    final visibleHabits = habitProvider.visibleHabits;
    final completedToday = habitProvider.getCompletedCountForDate(DateTime.now());
    final totalToday = visibleHabits.length;

    final screens = [
      _buildHomeContent(isDark, habitProvider, userProvider, visibleHabits, completedToday, totalToday),
      const StatisticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildAddButton(),
                _buildNavItem(Icons.person_outline, 'Profile', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    bool isDark,
    HabitProvider habitProvider,
    UserProvider userProvider,
    List<Habit> allVisibleHabits,
    int completedToday,
    int totalToday,
  ) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');
    final percentage = habitProvider.getTodayCompletionPercent() / 100.0;
    final currentStreak = habitProvider.calculateCurrentStreak();
    final userName = userProvider.greetingName;
    
    // Filter visible habits by date
    final visibleHabits = allVisibleHabits.where((h) => habitExistedOnDate(h, _selectedDate)).toList();

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showCalendarModal(),
                      child: _buildHeaderIcon(Icons.calendar_today_outlined),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _openWeeklyReport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: const Color(0xFFFF6B8A).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📊', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 4),
                            Text(
                              'Week',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF6B8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9F43), Color(0xFFFF6584)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.track_changes, color: Colors.white, size: 18),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB3C6), Color(0xFFFFD6A5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(child: Text(userProvider.genderEmoji, style: const TextStyle(fontSize: 18))),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Greeting
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $userName',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalToday > 0 && completedToday == totalToday
                          ? 'Amazing! All habits completed! 🎉'
                          : 'Great, your daily plan is almost done!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F43).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak days',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF9F43),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Calendar Strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: CalendarStrip(
              selectedDate: _selectedDate,
              today: DateTime.now(),
              dateStates: _getCompletedDatesMap(habitProvider),
              onDateSelected: _onDateSelected,
            ),
          ),
        ),

        // Activity Rings (only show for today)
        if (_isViewingToday)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ActivityRings(
                progress: percentage,
                size: 160,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      percentage >= 1 ? '🎉' : (percentage >= 0.7 ? '😇' : '💪'),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      percentage >= 1 
                        ? 'Completed!' 
                        : (percentage >= 0.7 ? 'Almost Done!' : '${(percentage * 100).toInt()}%'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Widget Promo Card (only show for today)
        if (_isViewingToday && _showWidgetCard)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('📱', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Home Screen',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'See habits without opening app',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showAddWidgetDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Date Header Banner (show for past dates)
        if (!_isViewingToday)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _goToToday,
                      child: const Icon(Icons.arrow_back_ios, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6584),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Date label with compact mode toggle
        if (_isViewingToday)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(now),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // Compact mode toggle button
                  GestureDetector(
                    onTap: _toggleCompactMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCompactMode
                            ? (isDark ? const Color(0xFF4A4A6A) : const Color(0xFFE0E0FF))
                            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCompactMode
                              ? const Color(0xFF6B6BFF)
                              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCompactMode ? Icons.view_agenda : Icons.view_agenda_outlined,
                            size: 14,
                            color: _isCompactMode
                                ? const Color(0xFF6B6BFF)
                                : (isDark ? const Color(0xFF888888) : const Color(0xFF666666)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCompactMode ? 'Compact' : 'Normal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isCompactMode
                                  ? const Color(0xFF6B6BFF)
                                  : (isDark ? const Color(0xFF888888) : const Color(0xFF666666)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Focus mode tip
        if (_isViewingToday && _showFocusTip)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A4A6A) : const Color(0xFFD0D0FF),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Long-press any habit to start a Focus Session!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFB0B0FF) : const Color(0xFF5050AA),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismissFocusTip,
                      child: Icon(Icons.close, size: 16,
                        color: isDark ? Colors.grey : const Color(0xFF9090CC)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Habits list - normal or compact mode
        visibleHabits.isEmpty
          ? SliverToBoxAdapter(
              child: _buildEmptyState(isDark),
            )
          : _isViewingToday
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = visibleHabits[index];
                      final isCompleted = habitProvider.isHabitCompletedToday(habit.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                        child: _isCompactMode
                            ? _buildCompactHabitRow(habit, isCompleted, habitProvider, true)
                            : _buildHabitCardWithProgress(habit, isCompleted, habitProvider, true),
                      );
                    },
                    childCount: visibleHabits.length,
                  ),
                )
              : _buildHistoryViewSliver(habitProvider, visibleHabits),

        // Summary card for history view
        if (!_isViewingToday && visibleHabits.isNotEmpty)
          _buildHistorySummarySliver(habitProvider, visibleHabits),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // "Browse Templates" Quick Action within Empty State
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TemplatePacksScreen(),
              )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
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
            
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8EC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.add_task_outlined,
                size: 40,
                color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first habit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected 
                ? const Color(0xFF111111) 
                : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected 
                ? Colors.white 
                : (isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA)),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF111111))
                : (isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _navigateToManageHabits,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  void _navigateToManageHabits() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageHabitsScreen()),
    );
  }

  void _showCalendarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CalendarModal(),
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

  Map<DateTime, String> _getCompletedDatesMap(HabitProvider provider) {
    final Map<DateTime, String> completedMap = {};
    final today = DateTime.now();
    
    // Check last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (provider.isDayComplete(date)) {
        completedMap[normalizedDate] = 'complete';
      } else if (provider.isDayPartial(date)) {
        completedMap[normalizedDate] = 'partial';
      } else {
        completedMap[normalizedDate] = 'none';
      }
    }
    
    return completedMap;
  }

  Widget _buildHabitCardWithProgress(
    Habit habit,
    bool isCompleted,
    HabitProvider provider,
    bool isInteractive,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    _initStrikeAnimation(habit.id);
    
    return GestureDetector(
      onLongPress: isInteractive ? () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(habit.icon, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(habit.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF111111),
                    )),
                  const SizedBox(height: 6),
                  const Text('Long press options',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FocusScreen(habit: habit),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Text('🎯  Start Focus Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text('Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? (isDark ? const Color(0xFF2C2C2E).withOpacity(0.5) : const Color(0xFFF0F0F0))
            : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isCompleted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(habit.colorValue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted
                                      ? (isDark ? const Color(0xFF888888) : const Color(0xFFAAAAAA))
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (provider.calculateHabitStreak(habit.id) > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🔥 ${provider.calculateHabitStreak(habit.id)} days',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF9F43),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (isCompleted && _isViewingToday) ...[
                          Builder(builder: (context) {
                            final log = provider.getRecordForDate(habit.id, _selectedDate);
                            if (log != null && log.completedAt != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '✅ Done at ${_formatTime(log.completedAt!)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ],
                    ),
                  ),
                  if (isInteractive)
                    _buildCheckButton(habit, isCompleted, provider)
                  else
                    _buildReadOnlyStatus(isCompleted),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCheckButton(Habit habit, bool isCompleted, HabitProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.toggleHabit(habit.id, DateTime.now());
        if (isCompleted) {
          _onHabitUndone(habit.id);
        } else {
          _onHabitDone(habit.id);
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFF0F0F0),
          border: isCompleted ? null : Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // NEW: Compact habit row - emoji + name + checkmark in one thin row
  Widget _buildCompactHabitRow(
    Habit habit,
    bool isCompleted,
    HabitProvider provider,
    bool isInteractive,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isInteractive
          ? () {
              provider.toggleHabit(habit.id, DateTime.now());
              if (isCompleted) {
                _onHabitUndone(habit.id);
              } else {
                _onHabitDone(habit.id);
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark ? const Color(0xFF2C2C2E).withOpacity(0.5) : const Color(0xFFF0F0F0))
              : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0))
                : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8EC)),
          ),
        ),
        child: Row(
          children: [
            // Emoji icon
            Text(habit.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            // Name with strikethrough if completed
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? (isDark ? const Color(0xFF888888) : const Color(0xFFAAAAAA))
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            // Compact check indicator
            if (isInteractive)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF4CAF50) : Colors.transparent,
                  border: isCompleted ? null : Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : const SizedBox.shrink(),
                ),
              )
            else if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18)
            else
              const Icon(Icons.circle_outlined, color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyStatus(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE8FFF0) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? '✅ completed' : '❌ missed',
        style: TextStyle(
          fontSize: 12,
          color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFF6B8A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHistoryViewSliver(HabitProvider provider, List<Habit> visibleHabits) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final habit = visibleHabits[index];
          final isCompleted = provider.getRecordForDate(habit.id, _selectedDate)?.isPunched ?? false;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFE8FFF0) : const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : const Color(0xFFFF6B8A).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(habit.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Builder(builder: (context) {
                      final log = provider.getRecordForDate(habit.id, _selectedDate);
                      if (log != null && log.completedAt != null) {
                        return Text(
                          _formatTime(log.completedAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const Text(
                        '✅ completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    })
                  else
                    const Text(
                      '❌ missed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        childCount: visibleHabits.length,
      ),
    );
  }

  Widget _buildHistorySummarySliver(HabitProvider provider, List<Habit> visibleHabits) {
    int completed = 0;
    for (final habit in visibleHabits) {
      if (provider.getRecordForDate(habit.id, _selectedDate)?.isPunched ?? false) {
        completed++;
      }
    }
    final total = visibleHabits.length;
    final pct = total > 0 ? (completed / total * 100).round() : 0;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completed/$total completed',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: pct >= 80
                    ? const Color(0xFF4CAF50)
                    : pct >= 50
                        ? const Color(0xFFFF9F43)
                        : const Color(0xFFFF6B8A),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the strike line animation
class StrikeLinePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  StrikeLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    final endX = size.width * progress;

    canvas.drawLine(
      Offset(0, y),
      Offset(endX, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(StrikeLinePainter old) =>
      old.progress != progress || old.color != color;
}
