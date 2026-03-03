package com.example.habit_punch

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONArray

class WidgetToggleReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "HabitWidget"
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra("habit_id") ?: return
        Log.d(TAG, "TOGGLE received for habit_id=$habitId")

        // KEY FIX: Use applicationContext to bypass Android's SharedPreferences cache
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val allPrefs = prefs.all
        val habitsJsonStr = allPrefs["flutter.widget.habits_json"] as? String ?: "[]"

        try {
            val habits = JSONArray(habitsJsonStr)
            var doneCount = 0
            var totalCount = habits.length()

            // Toggle the target habit
            for (i in 0 until habits.length()) {
                val habit = habits.getJSONObject(i)
                if (habit.optString("id", "") == habitId) {
                    val wasDone = habit.optBoolean("todayDone", false)
                    habit.put("todayDone", !wasDone)
                    Log.d(TAG, "TOGGLE habit=$habitId wasDone=$wasDone nowDone=${!wasDone}")
                }
                if (habit.optBoolean("todayDone", false)) {
                    doneCount++
                }
            }

            val completionPct = if (totalCount > 0) (doneCount * 100 / totalCount) else 0

            // Save updated data with commit() for immediate persistence
            val editor = prefs.edit()
            editor.putString("flutter.widget.habits_json", habits.toString())
            editor.putInt("flutter.widget.done_count", doneCount)
            editor.putInt("flutter.widget.completion_pct", completionPct)

            // Save pending toggles for Flutter sync - use widget. prefix (plugin adds flutter.)
            val pendingJson = allPrefs["flutter.widget.pending_toggles"] as? String ?: "[]"
            val pending = try { JSONArray(pendingJson) } catch (e: Exception) { JSONArray() }
            // Check if already pending, remove if so (toggle back); otherwise add
            var found = false
            for (i in 0 until pending.length()) {
                if (pending.getString(i) == habitId) {
                    pending.remove(i)
                    found = true
                    break
                }
            }
            if (!found) {
                pending.put(habitId)
            }
            editor.putString("widget.pending_toggles", pending.toString())
            editor.commit() // commit() not apply() — must be synchronous

            Log.d(TAG, "TOGGLE saved done=$doneCount total=$totalCount pct=$completionPct pending=$pending")

            // Trigger widget redraw for both providers
            val mgr = AppWidgetManager.getInstance(context)

            val mediumIds = mgr.getAppWidgetIds(
                ComponentName(context, HabitWidgetMediumProvider::class.java)
            )
            if (mediumIds.isNotEmpty()) {
                val updateIntent = Intent(context, HabitWidgetMediumProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, mediumIds)
                }
                context.sendBroadcast(updateIntent)
            }

            val smallIds = mgr.getAppWidgetIds(
                ComponentName(context, HabitWidgetSmallProvider::class.java)
            )
            if (smallIds.isNotEmpty()) {
                val updateIntent = Intent(context, HabitWidgetSmallProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, smallIds)
                }
                context.sendBroadcast(updateIntent)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error toggling habit", e)
        }
    }
}
