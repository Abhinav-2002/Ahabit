package com.example.habit_punch

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class HabitWidgetMediumProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "HabitWidget"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // Layout IDs for each habit row - now supports 7 habits
        private val ROW_IDS = intArrayOf(
            R.id.habit_row_0, R.id.habit_row_1, R.id.habit_row_2,
            R.id.habit_row_3, R.id.habit_row_4, R.id.habit_row_5, R.id.habit_row_6
        )
        private val ICON_IDS = intArrayOf(
            R.id.habit_icon_0, R.id.habit_icon_1, R.id.habit_icon_2,
            R.id.habit_icon_3, R.id.habit_icon_4, R.id.habit_icon_5, R.id.habit_icon_6
        )
        private val NAME_IDS = intArrayOf(
            R.id.habit_name_0, R.id.habit_name_1, R.id.habit_name_2,
            R.id.habit_name_3, R.id.habit_name_4, R.id.habit_name_5, R.id.habit_name_6
        )
        private val CHECK_IDS = intArrayOf(
            R.id.habit_check_0, R.id.habit_check_1, R.id.habit_check_2,
            R.id.habit_check_3, R.id.habit_check_4, R.id.habit_check_5, R.id.habit_check_6
        )
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "MEDIUM onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "MEDIUM onReceive action=${intent.action}")
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, HabitWidgetMediumProvider::class.java))
            Log.d(TAG, "MEDIUM onUpdate triggered for ${ids.size} widgets")
            onUpdate(context, mgr, ids)
        }
    }

    fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "MEDIUM updateAppWidget START for id=$appWidgetId")
        
        // Create completely fresh RemoteViews instance
        val views = RemoteViews(context.packageName, R.layout.widget_medium_layout)
        
        // KEY FIX: Use applicationContext to bypass Android's SharedPreferences cache
        // This forces a fresh read from disk every time
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Log ALL SharedPreferences keys for debugging
        val allEntries = prefs.all
        Log.d(TAG, "MEDIUM SharedPreferences has ${allEntries.size} entries")
        
        // Check specifically for our widget keys
        val hasStreak = prefs.contains("widget.streak")
        val hasDone = prefs.contains("widget.done_count")
        val hasHabits = prefs.contains("widget.habits_json")
        Log.d(TAG, "MEDIUM has widget.streak=$hasStreak, widget.done_count=$hasDone, widget.habits_json=$hasHabits")
        
        for ((key, value) in allEntries) {
            val displayValue = when (value) {
                is String -> value.take(50)
                else -> value.toString()
            }
            Log.d(TAG, "MEDIUM PREFS: $key = $displayValue")
        }

        // Read data using correct flutter.widget prefix
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
        
        val streak = getIntValue("flutter.widget.streak")
        val doneCount = getIntValue("flutter.widget.done_count")
        val totalCount = getIntValue("flutter.widget.total_count")
        val completionPct = getIntValue("flutter.widget.completion_pct")
        val dateStr = allPrefs["flutter.widget.date_str"] as? String ?: ""
        val habitsJsonStr = allPrefs["flutter.widget.habits_json"] as? String ?: "[]"

        // KEY LOG: Show exactly what was read so we can compare with Flutter logs
        Log.d(TAG, "WIDGET READ: streak=$streak done=$doneCount/$totalCount pct=$completionPct% habits=${habitsJsonStr.length}")

        // Set date only
        val displayDate = if (dateStr.isNotEmpty()) dateStr else "Today"
        views.setTextViewText(R.id.widget_date, displayDate)
        Log.d(TAG, "MEDIUM SET date = '$displayDate'")

        // Parse habits and set rows - supports up to 7 habits
        try {
            val habits = JSONArray(habitsJsonStr)
            val count = minOf(habits.length(), 7)
            
            Log.d(TAG, "MEDIUM Parsing habits JSON: array length=${habits.length()}, will display $count habits")

            if (count == 0) {
                // No incomplete habits — show empty-state message in row 0
                val emptyMsg = allPrefs["flutter.widget.empty_message"] as? String
                    ?: "All habits done! \uD83C\uDF89"
                views.setViewVisibility(ROW_IDS[0], View.VISIBLE)
                views.setTextViewText(ICON_IDS[0], "\u2705")
                views.setTextViewText(NAME_IDS[0], emptyMsg)
                views.setImageViewResource(CHECK_IDS[0], R.drawable.widget_check_done)
                // No toggle PendingIntent — tapping the row opens the app instead
                Log.d(TAG, "MEDIUM empty state: $emptyMsg")
                for (i in 1 until 7) {
                    views.setViewVisibility(ROW_IDS[i], View.GONE)
                }
            } else {
                for (i in 0 until 7) {
                    if (i < count) {
                        val habit = habits.getJSONObject(i)
                        val id = habit.optString("id", "")
                        val name = habit.optString("name", "")
                        val icon = habit.optString("icon", "")
                        val todayDone = habit.optBoolean("todayDone", false)

                        views.setViewVisibility(ROW_IDS[i], View.VISIBLE)
                        views.setTextViewText(ICON_IDS[i], icon)
                        views.setTextViewText(NAME_IDS[i], name)

                        val checkDrawable = if (todayDone) R.drawable.widget_check_done else R.drawable.widget_check_empty
                        views.setImageViewResource(CHECK_IDS[i], checkDrawable)

                        // Set up toggle PendingIntent for checkbox
                        val toggleIntent = Intent(context, WidgetToggleReceiver::class.java).apply {
                            action = "com.example.habit_punch.TOGGLE_HABIT"
                            putExtra("habit_id", id)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            context, id.hashCode(), toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(CHECK_IDS[i], pendingIntent)

                        Log.d(TAG, "MEDIUM ROW $i: icon='$icon' name='$name' done=$todayDone id=$id")
                    } else {
                        views.setViewVisibility(ROW_IDS[i], View.GONE)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "MEDIUM Error parsing habits_json: ${e.message}")
            // Hide all rows on error
            for (i in 0 until 7) {
                views.setViewVisibility(ROW_IDS[i], View.GONE)
            }
        }

        // Setup click to open app on root
        val launchIntent = Intent(context, MainActivity::class.java)
        val launchPending = PendingIntent.getActivity(
            context, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchPending)

        // Force update - single update without broadcast loop
        appWidgetManager.updateAppWidget(appWidgetId, views)
        
        Log.d(TAG, "MEDIUM updateAppWidget END for id=$appWidgetId")
    }
}
