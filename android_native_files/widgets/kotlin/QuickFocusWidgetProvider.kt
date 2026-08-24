package com.oneir.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Widget 2 -- "Quick Focus". Tapping it launches the app carrying a
 * `oneir://widget/focus` Uri, via home_widget's own `HomeWidgetLaunchIntent`
 * helper -- the same mechanism `HomeWidget.widgetClicked` /
 * `HomeWidget.initiallyLaunchedFromHomeWidget()` already listen for on the
 * Dart side (see OneirWidgetService.consumeInitialLaunch/registerLaunchListener),
 * so no custom MethodChannel or manual MainActivity intent-reading is
 * needed. (Not the raw `putExtra("ONEIR_WIDGET_ACTION", ...)` this used to
 * carry -- that extra was never actually read by anything on either side;
 * see SETUP.md for the full story.)
 * Shows a live countdown once a session is running, via
 * OneirWidgetService.updateQuickFocus(isRunning:, remainingMinutes:).
 */
class QuickFocusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id)
        }
    }

    private fun updateOne(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_quick_focus)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val isRunning = prefs.getBoolean("quick_focus_running", false)
        val remaining = prefs.getInt("quick_focus_remaining", 25)

        views.setTextViewText(R.id.quick_focus_value, if (isRunning) "$remaining min left" else "25 min")

        // Vanya's occasional line during a session -- decided in Dart by
        // OneirWidgetService.updateQuickFocus() (once per session, at the
        // halfway point, or "Nice work." on a genuine completion). Empty
        // most refreshes on purpose, same restraint rule as every other
        // widget message row.
        val message = prefs.getString("quick_focus_message", null)
        if (message.isNullOrBlank()) {
            views.setViewVisibility(R.id.quick_focus_message, android.view.View.GONE)
        } else {
            views.setTextViewText(R.id.quick_focus_message, message)
            views.setViewVisibility(R.id.quick_focus_message, android.view.View.VISIBLE)
        }

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("oneir://widget/focus")
        )
        views.setOnClickPendingIntent(R.id.quick_focus_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
