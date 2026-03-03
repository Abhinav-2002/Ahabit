package com.example.habit_punch

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "HabitWidget"
        private const val CHANNEL = "com.example.habit_punch/widget"
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity created")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "commitAndUpdate" -> {
                        try {
                            Log.d(TAG, "commitAndUpdate: Starting widget update")
                            
                            // Force SharedPreferences to disk
                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            val committed = prefs.edit().commit()
                            Log.d(TAG, "commitAndUpdate: SharedPreferences committed=$committed")

                            // Trigger widget updates for both providers
                            val mgr = AppWidgetManager.getInstance(this)
                            var updatedCount = 0

                            val mediumIds = mgr.getAppWidgetIds(
                                ComponentName(this, HabitWidgetMediumProvider::class.java)
                            )
                            if (mediumIds.isNotEmpty()) {
                                Log.d(TAG, "commitAndUpdate: updating ${mediumIds.size} medium widgets")
                                for (id in mediumIds) {
                                    try {
                                        HabitWidgetMediumProvider().updateAppWidget(this, mgr, id)
                                        updatedCount++
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error updating medium widget $id", e)
                                    }
                                }
                            }

                            val smallIds = mgr.getAppWidgetIds(
                                ComponentName(this, HabitWidgetSmallProvider::class.java)
                            )
                            if (smallIds.isNotEmpty()) {
                                Log.d(TAG, "commitAndUpdate: updating ${smallIds.size} small widgets")
                                for (id in smallIds) {
                                    try {
                                        HabitWidgetSmallProvider().updateAppWidget(this, mgr, id)
                                        updatedCount++
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error updating small widget $id", e)
                                    }
                                }
                            }

                            Log.d(TAG, "commitAndUpdate: Completed, updated $updatedCount widgets")
                            result.success(updatedCount)
                        } catch (e: Exception) {
                            Log.e(TAG, "commitAndUpdate error", e)
                            result.error("COMMIT_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
