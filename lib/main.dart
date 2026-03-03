import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';
import 'models/notice.dart';
import 'providers/habit_provider.dart';
import 'providers/notices_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_helper.dart';
import 'services/workmanager_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    try {
      // Initialize Hive
      await Hive.initFlutter();
      Hive.registerAdapter(HabitAdapter());
      Hive.registerAdapter(HabitLogAdapter());
      Hive.registerAdapter(NoticeAdapter());
      
      // Open boxes
      await Hive.openBox<Habit>('habits');
      await Hive.openBox<HabitLog>('habitLogs');
      await Hive.openBox<Notice>('notices');
      await Hive.openBox('settings');
      
      // Check onboarding status BEFORE runApp
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
      
      // Initialize home widget
      try {
        await WidgetHelper.initialize();
      } catch (e) {
        debugPrint('WidgetHelper init failed (non-fatal): $e');
      }

      // Init notifications (creates channels, sets timezone, schedules all)
      try {
        final ns = NotificationService();
        await ns.init();
        await ns.requestPermissions();
        await ns.rescheduleAll();
        debugPrint('✅ Notification init complete');
      } catch (e) {
        debugPrint('❌ Notification init failed: $e');
      }

      // Init Workmanager for background tasks
      try {
        await WorkmanagerService.initialize();
        final incompleteEnabled = prefs.getBool('incomplete_reminders_enabled') ?? false;
        if (incompleteEnabled) {
          final interval = prefs.getInt('incomplete_reminder_interval') ?? 2;
          await WorkmanagerService.scheduleIncompleteHabitsTask(interval);
          debugPrint('✅ Workmanager incomplete task scheduled');
        }
        // Always schedule midnight reset for widget refresh
        await WorkmanagerService.scheduleMidnightResetTask();
        debugPrint('✅ Workmanager midnight reset scheduled');
      } catch (e) {
        debugPrint('❌ Workmanager init failed: $e');
      }
      
      runApp(MyApp(startScreen: onboardingDone ? 'home' : 'onboarding'));
    } catch (e, stack) {
      debugPrint('FATAL startup error: $e');
      debugPrint('Stack: $stack');
      // Show a basic error app so the screen isn't black
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ));
    }
  }, (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrint('Stack: $stack');
  });
}

class MyApp extends StatefulWidget {
  final String startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkWidgetLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndUpdateWidget();
      // Reschedule notifications in case they were cleared by OS
      NotificationService().rescheduleAll();
    }
  }

  Future<void> _syncAndUpdateWidget() async {
    final context = this.context;
    if (context.mounted) {
      try {
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        // Sync any pending toggles from widget checkboxes
        await WidgetHelper.syncPendingToggles(habitProvider);
        await WidgetHelper.forceWidgetUpdate();
      } catch (e) {
        // Provider not available yet, just update widget from boxes
        await WidgetHelper.forceWidgetUpdate();
      }
    }
  }

  Future<void> _checkWidgetLaunch() async {
    final habitId = await WidgetHelper.getTappedHabitId();
    if (habitId != null && habitId.isNotEmpty) {
      final context = this.context;
      if (context.mounted) {
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        await habitProvider.toggleHabit(habitId, DateTime.now());
        await WidgetHelper.updateWidget(habitProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => NoticesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Ahabit',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: widget.startScreen == 'home' ? const HomeScreen() : const SplashScreen(),
          );
        },
      ),
    );
  }
}
