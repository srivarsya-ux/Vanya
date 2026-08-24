package com.oneir.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import java.util.Calendar

/**
 * Widget 3 -- "Vanya Daily Check-in". A standing prompt with an
 * "+ Add task" shortcut that launches the app carrying a
 * `oneir://widget/quick_add_task` Uri via home_widget's own
 * `HomeWidgetLaunchIntent` helper (see QuickFocusWidgetProvider's doc
 * comment and SETUP.md for why this replaced the earlier unread
 * `ONEIR_WIDGET_ACTION` intent extra) -- picked up on the Dart side by
 * OneirWidgetService.consumeInitialLaunch/registerLaunchListener, which
 * routes it to TasksScreen(autoFocusAdd: true).
 *
 * The prompt line itself (see [promptFor]) now evolves instead of being
 * one fixed sentence forever -- a morning greeting before anything's
 * touched, quiet encouragement once a task is in progress, and a "that's
 * everything" line once the day's tasks are all done. This reads the SAME
 * `todays_focus_tasks` data Dart already pushes from
 * OneirWidgetService.updateTodaysFocus() for Widget 1 -- all three
 * widgets share one SharedPreferences file, so no new Dart plumbing was
 * needed to make this widget say something real.
 */
class VanyaCheckInWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id)
        }
    }

    private fun updateOne(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_vanya_checkin)

        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("todays_focus_tasks", null)
        views.setTextViewText(R.id.check_in_prompt, promptFor(raw))

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("oneir://widget/quick_add_task")
        )
        views.setOnClickPendingIntent(R.id.check_in_add_task_button, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * No tasks pushed yet -- the standing question, with a morning
     * greeting folded in early in the day rather than a separate line
     * (this widget only has room for one line of prompt text).
     * Tasks exist but none done -- stays the standing question; nothing
     * to encourage yet since nothing's been started.
     * Some done, some not -- the brief's "you're doing well" beat.
     * All done -- the brief's "that's one down" beat, scaled up to
     * "everything," matching Widget 1's own completion wording.
     */
    private fun promptFor(raw: String?): String {
        val tasks = try {
            if (raw.isNullOrEmpty()) null else JSONArray(raw)
        } catch (e: Exception) {
            null
        }

        if (tasks == null || tasks.length() == 0) {
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            return if (hour in 4..10) {
                "Good morning. What's one thing you want to get done today?"
            } else {
                "What's one thing you want to get done today?"
            }
        }

        var done = 0
        for (i in 0 until tasks.length()) {
            if (tasks.getJSONObject(i).optBoolean("done", false)) done++
        }

        return when {
            done >= tasks.length() -> "That's everything today."
            done > 0 -> "You're doing well."
            else -> "What's one thing you want to get done today?"
        }
    }
}
