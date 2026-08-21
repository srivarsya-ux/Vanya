package com.oneir.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Widget 3 -- "Vanya Daily Check-in". A standing prompt with an
 * "+ Add task" shortcut that launches the app carrying a
 * `oneir://widget/quick_add_task` Uri via home_widget's own
 * `HomeWidgetLaunchIntent` helper (see QuickFocusWidgetProvider's doc
 * comment and SETUP.md for why this replaced the earlier unread
 * `ONEIR_WIDGET_ACTION` intent extra) -- picked up on the Dart side by
 * OneirWidgetService.consumeInitialLaunch/registerLaunchListener, which
 * routes it to TasksScreen(autoFocusAdd: true).
 */
class VanyaCheckInWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id)
        }
    }

    private fun updateOne(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_vanya_checkin)

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("oneir://widget/quick_add_task")
        )
        views.setOnClickPendingIntent(R.id.check_in_add_task_button, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
