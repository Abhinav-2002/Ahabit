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

        // goAsync() keeps the process alive until finish() is called,
        // preventing Android from killing it before AppWidgetManager IPC completes.
        val pendingResult = goAsync()

        Thread {
            try {
                val appCtx = context.applicationContext
                val prefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val allPrefs = prefs.all
                val habitsJsonStr = allPrefs["flutter.widget.habits_json"] as? String ?: "[]"

                val habits = JSONArray(habitsJsonStr)

                // ── 1. Toggle the target habit ─────────────────────────────────────
                var nowDone = false
                for (i in 0 until habits.length()) {
                    val habit = habits.getJSONObject(i)
                    if (habit.optString("id", "") == habitId) {
                        val wasDone = habit.optBoolean("todayDone", false)
                        nowDone = !wasDone
                        habit.put("todayDone", nowDone)
                        Log.d(TAG, "TOGGLE habit=$habitId wasDone=$wasDone nowDone=$nowDone")
                    }
                }

                // ── 2. Recalculate stats from stored totals ────────────────────────
                val storedTotal = (allPrefs["flutter.widget.total_count"] as? Number)?.toInt()
                    ?: habits.length()
                val storedDone = (allPrefs["flutter.widget.done_count"] as? Number)?.toInt() ?: 0
                val doneCount = if (nowDone) storedDone + 1 else maxOf(0, storedDone - 1)
                val completionPct = if (storedTotal > 0) (doneCount * 100 / storedTotal) else 0

                // ── 3. Filter to INCOMPLETE habits only (tapped one disappears) ────
                val incompleteHabits = JSONArray()
                for (i in 0 until habits.length()) {
                    val habit = habits.getJSONObject(i)
                    if (!habit.optBoolean("todayDone", false)) {
                        incompleteHabits.put(habit)
                    }
                }

                // ── 4. Empty-state message ─────────────────────────────────────────
                val emptyMessage = when {
                    storedTotal == 0         -> "No habits yet"
                    doneCount >= storedTotal -> "All habits done! \uD83C\uDF89"
                    else                     -> ""
                }

                // ── 5. Pending toggles for Dart Hive sync on next app open ─────────
                val pendingJson = allPrefs["flutter.widget.pending_toggles"] as? String ?: "[]"
                val pending = try { JSONArray(pendingJson) } catch (e: Exception) { JSONArray() }
                var found = false
                for (i in 0 until pending.length()) {
                    if (pending.getString(i) == habitId) { pending.remove(i); found = true; break }
                }
                if (!found) pending.put(habitId)

                // ── 6. Commit everything atomically ───────────────────────────────
                prefs.edit()
                    .putString("flutter.widget.habits_json",   incompleteHabits.toString())
                    .putString("flutter.widget.empty_message", emptyMessage)
                    .putInt("flutter.widget.done_count",       doneCount)
                    .putInt("flutter.widget.completion_pct",   completionPct)
                    .putString("flutter.widget.pending_toggles", pending.toString())
                    .commit()

                Log.d(TAG, "TOGGLE committed: done=$doneCount/$storedTotal incomplete=${incompleteHabits.length()} empty='$emptyMessage'")

                // ── 7. Update widgets directly via AppWidgetManager ────────────────
                val mgr = AppWidgetManager.getInstance(appCtx)

                val mediumProvider = HabitWidgetMediumProvider()
                val mediumIds = mgr.getAppWidgetIds(
                    ComponentName(appCtx, HabitWidgetMediumProvider::class.java)
                )
                for (id in mediumIds) {
                    try {
                        mediumProvider.updateAppWidget(appCtx, mgr, id)
                        Log.d(TAG, "TOGGLE: medium widget $id updated")
                    } catch (e: Exception) {
                        Log.e(TAG, "TOGGLE: failed to update medium widget $id", e)
                    }
                }

                val smallProvider = HabitWidgetSmallProvider()
                val smallIds = mgr.getAppWidgetIds(
                    ComponentName(appCtx, HabitWidgetSmallProvider::class.java)
                )
                for (id in smallIds) {
                    try {
                        smallProvider.updateAppWidget(appCtx, mgr, id)
                        Log.d(TAG, "TOGGLE: small widget $id updated")
                    } catch (e: Exception) {
                        Log.e(TAG, "TOGGLE: failed to update small widget $id", e)
                    }
                }

                Log.d(TAG, "TOGGLE: done (medium=${mediumIds.size} small=${smallIds.size})")

            } catch (e: Exception) {
                Log.e(TAG, "TOGGLE: fatal error", e)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }
}
