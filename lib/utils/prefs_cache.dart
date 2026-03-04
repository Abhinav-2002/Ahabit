import 'package:shared_preferences/shared_preferences.dart';

/// Singleton wrapper that eliminates repeated [SharedPreferences.getInstance]
/// calls. Call [init] once in [main] after [WidgetsFlutterBinding.ensureInitialized].
///
/// Background Workmanager isolates never call [main], so they use the async
/// [instance] getter which lazily initialises safely.
class PrefsCache {
  PrefsCache._();

  static SharedPreferences? _prefs;

  /// Eagerly initialise — call once in [main] before [runApp].
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Always-safe async getter. Lazily initialises if not already done
  /// (safe for background Workmanager isolates).
  static Future<SharedPreferences> get instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Synchronous getter — only valid after [init] has completed.
  /// Throws in debug mode if called before [init].
  static SharedPreferences get requireInstance {
    assert(_prefs != null,
        'PrefsCache.init() must be awaited before using requireInstance.');
    return _prefs!;
  }

  /// Force-reloads from disk. Use after a Kotlin widget write that bypasses
  /// Flutter's in-memory cache.
  static Future<void> reload() async {
    await (await instance).reload();
  }
}
