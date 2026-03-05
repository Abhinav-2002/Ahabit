package com.ahabit.tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.util.Log
import android.widget.RemoteViews

class HabitWidgetSmallProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "HabitWidget"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // Layout IDs for 4 habit rows
        private val ROW_IDS = intArrayOf(
            R.id.habit_row_0, R.id.habit_row_1, R.id.habit_row_2, R.id.habit_row_3
        )
        private val NAME_IDS = intArrayOf(
            R.id.habit_name_0, R.id.habit_name_1, R.id.habit_name_2, R.id.habit_name_3
        )
        private val CHECK_IDS = intArrayOf(
            R.id.habit_check_0, R.id.habit_check_1, R.id.habit_check_2, R.id.habit_check_3
        )
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "SMALL onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "SMALL onReceive action=${intent.action}")
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, HabitWidgetSmallProvider::class.java))
            Log.d(TAG, "SMALL onUpdate triggered for ${ids.size} widgets")
            onUpdate(context, mgr, ids)
        }
    }

    fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "SMALL updateAppWidget START for id=$appWidgetId")
        
        // Create completely fresh RemoteViews instance
        val views = RemoteViews(context.packageName, R.layout.widget_small_layout)
        
        // KEY FIX: Use applicationContext to bypass Android's SharedPreferences cache
        // This forces a fresh read from disk every time
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Log ALL SharedPreferences keys for debugging
        val allEntries = prefs.all
        Log.d(TAG, "SMALL SharedPreferences has ${allEntries.size} entries")
        
        // Check specifically for our widget keys
        val hasStreak = prefs.contains("widget.streak")
        val hasDone = prefs.contains("widget.done_count")
        val hasHabits = prefs.contains("widget.habits_json")
        Log.d(TAG, "SMALL has widget.streak=$hasStreak, widget.done_count=$hasDone, widget.habits_json=$hasHabits")
        
        for ((key, value) in allEntries.entries.take(10)) {
            val displayValue = when (value) {
                is String -> value.take(50)
                else -> value.toString()
            }
            Log.d(TAG, "SMALL PREFS: $key = $displayValue")
        }

        // Read data - use getAll() first to bypass any caching with correct flutter.widget prefix
        val allPrefs = prefs.all
        
        // Helper to read Int from SharedPreferences (handles both Int and Long types)
        fun getIntValue(key: String): Int {
            val value = allPrefs[key]
            return when (value) {
                is Int -> value
                is Long -> value.toInt()
                is Number -> value.toInt()
                else -> 0
            }
        }
        
        val doneCount = getIntValue("flutter.widget.done_count")
        val totalCount = getIntValue("flutter.widget.total_count")
        val dateStr = allPrefs["flutter.widget.date_str"] as? String ?: ""
        val habitsJsonStr = allPrefs["flutter.widget.habits_json"] as? String ?: "[]"

        // KEY LOG: Show exactly what was read
        Log.d(TAG, "SMALL WIDGET READ: done=$doneCount/$totalCount habits=${habitsJsonStr.length}")

        // Set date
        val displayDate = if (dateStr.isNotEmpty()) dateStr else "Today"
        views.setTextViewText(R.id.widget_date, displayDate)
        Log.d(TAG, "SMALL SET date = '$displayDate'")

        // Parse and display habits (max 4 for small widget)
        try {
            val habits = org.json.JSONArray(habitsJsonStr)
            val count = minOf(habits.length(), 4)

            Log.d(TAG, "SMALL Parsing habits: ${habits.length()} total, showing $count")

            if (count == 0) {
                // No incomplete habits — show empty-state message in row 0
                val emptyMsg = allPrefs["flutter.widget.empty_message"] as? String
                    ?: "All habits done! \uD83C\uDF89"
                views.setViewVisibility(ROW_IDS[0], android.view.View.VISIBLE)
                views.setTextViewText(NAME_IDS[0], emptyMsg)
                views.setImageViewResource(CHECK_IDS[0], R.drawable.widget_check_done)
                // No toggle PendingIntent — tapping the row opens the app instead
                Log.d(TAG, "SMALL empty state: $emptyMsg")
                for (i in 1 until 4) {
                    views.setViewVisibility(ROW_IDS[i], android.view.View.GONE)
                }
            } else {
                for (i in 0 until count) {
                    val habit = habits.getJSONObject(i)
                    val id = habit.optString("id", "")
                    val name = habit.optString("name", "")
                    val todayDone = habit.optBoolean("todayDone", false)

                    views.setViewVisibility(ROW_IDS[i], android.view.View.VISIBLE)
                    views.setTextViewText(NAME_IDS[i], name)

                    val checkDrawable = if (todayDone) R.drawable.widget_check_done else R.drawable.widget_check_empty
                    views.setImageViewResource(CHECK_IDS[i], checkDrawable)

                    // Set up toggle PendingIntent
                    val toggleIntent = android.content.Intent(context, WidgetToggleReceiver::class.java).apply {
                        action = "com.ahabit.tracker.TOGGLE_HABIT"
                        putExtra("habit_id", id)
                    }
                    val pendingIntent = android.app.PendingIntent.getBroadcast(
                        context, id.hashCode(), toggleIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(CHECK_IDS[i], pendingIntent)

                    Log.d(TAG, "SMALL ROW $i: name='$name' done=$todayDone")
                }

                // Hide remaining rows
                for (i in count until 4) {
                    views.setViewVisibility(ROW_IDS[i], android.view.View.GONE)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "SMALL Error parsing habits: ${e.message}")
            for (i in 0 until 4) {
                views.setViewVisibility(ROW_IDS[i], android.view.View.GONE)
            }
        }

        // Setup click to open app
        val launchIntent = Intent(context, MainActivity::class.java)
        val launchPending = PendingIntent.getActivity(
            context, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchPending)

        // Force update - single update without broadcast loop
        appWidgetManager.updateAppWidget(appWidgetId, views)
        
        Log.d(TAG, "SMALL updateAppWidget END for id=$appWidgetId")
    }
}
