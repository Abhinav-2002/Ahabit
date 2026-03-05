# =============================================================================
# Ahabit — ProGuard / R8 rules
# Applied for: flutter build apk --release  /  flutter build appbundle --release
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Flutter engine
#    The Flutter embedding and plugin registry are loaded reflectively at
#    runtime. Removing or renaming any class breaks the engine initialisation.
# -----------------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.**

# -----------------------------------------------------------------------------
# 2. audioplayers plugin  (xyz.luan.audioplayers / audioplayers_android v5.x)
#    The plugin registers its FlutterPlugin and AudioService subclasses via
#    reflection using the Flutter plugin registry. R8 strips them in release
#    builds because there are no direct Java/Kotlin references from app code.
#    MediaPlayer, ExoPlayer wrappers and the WrappedMediaPlayer are also
#    looked up reflectively by plugin internals.
# -----------------------------------------------------------------------------
-keep class xyz.luan.audioplayers.** { *; }
-keepclassmembers class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# -----------------------------------------------------------------------------
# 2. App-specific Kotlin classes
#    WidgetToggleReceiver and the two AppWidgetProviders are registered in
#    AndroidManifest.xml and invoked by the OS by name. MainActivity is the
#    Flutter entry point. Obfuscating any of these breaks the app.
# -----------------------------------------------------------------------------
-keep class com.ahabit.tracker.** { *; }

# -----------------------------------------------------------------------------
# 3. Android AppWidgetProvider subclasses (any package)
#    The home-screen widget framework instantiates providers by name from the
#    widget metadata XML. Renaming them silently breaks all widgets.
# -----------------------------------------------------------------------------
-keep class * extends android.appwidget.AppWidgetProvider { *; }

# -----------------------------------------------------------------------------
# 4. Android BroadcastReceiver subclasses (any package)
#    WidgetToggleReceiver receives PendingIntent broadcasts from the launcher.
#    The OS looks it up by the fully-qualified class name stored in the APK.
# -----------------------------------------------------------------------------
-keep class * extends android.content.BroadcastReceiver { *; }

# -----------------------------------------------------------------------------
# 5. Workmanager plugin  (be.tramckrijte.workmanager)
#    BackgroundWorker is instantiated by WorkManager via reflection using the
#    class name stored in SharedPreferences by the Dart side. The callback
#    handle is also stored as a Long and looked up at runtime.
# -----------------------------------------------------------------------------
-keep class be.tramckrijte.workmanager.** { *; }
-keepclassmembers class be.tramckrijte.workmanager.** { *; }
-dontwarn be.tramckrijte.workmanager.**

# WorkManager itself uses reflection internally
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-dontwarn androidx.work.**

# ListenableWorker subclasses are referenced by name in WorkManager's DB
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.work.Worker { *; }

# -----------------------------------------------------------------------------
# 6. HomeWidget plugin  (es.antonborri.home_widget)
#    Provides the Dart ↔ Android SharedPreferences bridge and the
#    HomeWidgetBackgroundIntent receiver. Removing these breaks widget data
#    writes and click callbacks.
# -----------------------------------------------------------------------------
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

# -----------------------------------------------------------------------------
# 7. Firebase / Google services
#    Firebase initialises via a ContentProvider registered in the manifest.
#    The GooglePlayServicesUtil and related classes are accessed reflectively.
# -----------------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }
-keepclassmembers class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics (if used in future)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# -----------------------------------------------------------------------------
# 8. Kotlin runtime & reflection
#    Kotlin uses its own metadata annotations (@Metadata) and reflection.
#    WorkManager's plugin also uses Kotlin reflection to invoke the Dart
#    callback dispatcher. Stripping these causes NoSuchMethodError at runtime.
# -----------------------------------------------------------------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.jvm.internal.** { *; }
-dontwarn kotlin.**

# Kotlin coroutines (used internally by WorkManager and plugins)
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# -----------------------------------------------------------------------------
# 9. Hive database
#    Hive is a pure-Dart library; its data lives in the Flutter engine.
#    No Java/Kotlin ProGuard rules are needed for Hive itself.
#    However, the Hive Flutter plugin registers a path provider on the
#    Android side — keep that.
# -----------------------------------------------------------------------------
-keep class com.tekartik.** { *; }        # path_provider
-dontwarn com.tekartik.**

# -----------------------------------------------------------------------------
# 10. SharedPreferences / platform channels
#     Used heavily for widget ↔ Dart data exchange. The platform-channel
#     method calls go through Flutter's standard codec — no special rules
#     needed beyond keeping the Flutter engine (rule 1).
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 11. AndroidX core / lifecycle (used by Flutter embedding)
# -----------------------------------------------------------------------------
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.** { *; }
-dontwarn androidx.lifecycle.**
-dontwarn androidx.core.**

# -----------------------------------------------------------------------------
# 12. JSON (org.json) — used in WidgetToggleReceiver for habit JSON parsing
# -----------------------------------------------------------------------------
-keep class org.json.** { *; }

# -----------------------------------------------------------------------------
# 13. General safety rules
#     Preserve annotations needed for serialisation, injection and reflection.
# -----------------------------------------------------------------------------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve enum constants (safe to keep everywhere)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve Parcelable implementations (used by Android OS internally)
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Preserve Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
