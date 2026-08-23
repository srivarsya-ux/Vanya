package com.oneir.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray

/**
 * Widget 1 -- "Today's Focus". Shows up to 3 tasks pushed from Dart via
 * OneirWidgetService.updateTodaysFocus() (lib/widgets_android/).
 *
 * Uses a fixed 3-row layout (task_row_1/2/3) rather than a
 * RemoteViewsService-backed ListView -- deliberately: the brief caps this
 * widget at 3 tasks, and a fixed layout is dramatically simpler/lighter
 * than standing up a full RemoteViewsFactory for a bounded, small list.
 * If a scrollable/unbounded task widget is ever wanted, that's the point
 * where a ListView-based rewrite would be worth it -- not needed for this.
 *
 * Unlike Widgets 2 and 3, this one has no distinct action to carry --
 * tapping it just opens the app (no Uri needed on the launch intent).
 * It previously had no click handling registered at all (the whole
 * widget was inert); wired up alongside the other two widgets' real
 * launch intents.
 */
class TodaysFocusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id)
        }
    }

    private fun updateOne(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_todays_focus)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("todays_focus_tasks", null)

        val rowIds = intArrayOf(R.id.task_row_1, R.id.task_row_2, R.id.task_row_3)
        val labelIds = intArrayOf(R.id.task_label_1, R.id.task_label_2, R.id.task_label_3)

        if (raw.isNullOrEmpty()) {
            views.setTextViewText(labelIds[0], "Open Oneir to add today's tasks")
            views.setViewVisibility(rowIds[0], android.view.View.VISIBLE)
            views.setViewVisibility(rowIds[1], android.view.View.GONE)
            views.setViewVisibility(rowIds[2], android.view.View.GONE)
        } else {
            try {
                val tasks = JSONArray(raw)
                for (i in rowIds.indices) {
                    if (i < tasks.length()) {
                        val task = tasks.getJSONObject(i)
                        val label = task.optString("label", "")
                        val done = task.optBoolean("done", false)
                        views.setTextViewText(labelIds[i], if (done) "\u2713 $label" else label)
                        views.setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(rowIds[i], android.view.View.GONE)
                    }
                }
            } catch (e: Exception) {
                views.setTextViewText(labelIds[0], "Open Oneir to add today's tasks")
                views.setViewVisibility(rowIds[0], android.view.View.VISIBLE)
                views.setViewVisibility(rowIds[1], android.view.View.GONE)
                views.setViewVisibility(rowIds[2], android.view.View.GONE)
            }
        }

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.todays_focus_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
