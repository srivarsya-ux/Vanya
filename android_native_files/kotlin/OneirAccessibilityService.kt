package com.oneir.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.preference.PreferenceManager
import android.view.accessibility.AccessibilityEvent

/**
 * The heart of Oneir's protection: listens system-wide for window-change
 * events (i.e. "a new app/screen just came to the foreground") and, if the
 * package that just opened is one the user marked as protected, launches
 * [InterruptionActivity] on top of it before the user can start scrolling.
 *
 * This only fires on real state changes (not polling), so it's both more
 * responsive and far less battery-hungry than repeatedly querying
 * UsageStatsManager.
 *
 * The protected-apps set is written by the Flutter side (see
 * lib/native/oneir_protection.dart -> ProtectedAppsScreen) into the same
 * SharedPreferences file Flutter's shared_preferences plugin uses, under
 * the key below, so both sides agree on one source of truth without needing
 * a running Flutter engine here.
 */
class OneirAccessibilityService : AccessibilityService() {

    companion object {
        // Matches the key shared_preferences (Flutter plugin) writes to when
        // storing a `List<String>` under the name "protected_apps" -- see
        // lib/native/oneir_protection.dart for the exact key it uses.
        private const val PREFS_KEY = "flutter.protected_apps"
        private const val COOLDOWN_MS = 3000L
    }

    private var lastInterruptedPackage: String? = null
    private var lastInterruptTime: Long = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        if (packageName == this.packageName) return // don't interrupt Oneir itself

        val protectedApps = readProtectedApps()
        if (packageName !in protectedApps) return

        val now = System.currentTimeMillis()
        val recentlyInterruptedSameApp = packageName == lastInterruptedPackage && (now - lastInterruptTime) < COOLDOWN_MS
        if (recentlyInterruptedSameApp) return // avoid re-triggering on the same app's internal navigation

        lastInterruptedPackage = packageName
        lastInterruptTime = now
        launchInterruption(packageName)
    }

    private fun readProtectedApps(): Set<String> {
        val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
        // shared_preferences (Flutter) stores string lists as a JSON-encoded string.
        val raw = prefs.getString(PREFS_KEY, null) ?: return emptySet()
        return try {
            raw.trim('[', ']')
                .split(",")
                .map { it.trim().trim('"') }
                .filter { it.isNotEmpty() }
                .toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun launchInterruption(packageName: String) {
        val intent = Intent(this, InterruptionActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(InterruptionActivity.EXTRA_PACKAGE_NAME, packageName)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        // Required override; nothing to clean up.
    }
}
