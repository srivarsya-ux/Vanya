package com.vanya.vanya_flutter

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent

/**
 * Detects foreground-app changes and, for a protected app with no valid
 * temporary access, starts [InterventionActivity] on top of it. That's
 * *all* this class does — per the architecture rule, it never builds an
 * `InterventionContext`, never talks to a reasoning service, never shows
 * UI itself. It only reads the lightweight [VanyaNativeStore] mirror to
 * decide whether to escalate to Flutter at all.
 *
 * Privacy: only ever reads `event.packageName` from
 * [TYPE_WINDOW_STATE_CHANGED][AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED]
 * events — never event text, node content, or any other field, even
 * though `canRetrieveWindowContent` is set (required for the event type
 * itself to fire reliably on some OEM skins). No typed text, messages, or
 * screenshots are ever read.
 */
class VanyaAccessibilityService : AccessibilityService() {
    companion object {
        /**
         * True from the moment an intervention Activity is launched until
         * it finishes — the debounce that stops one protected-app launch
         * from producing several stacked intervention screens when Android
         * fires multiple window-state-changed events for the same
         * transition (item 9: event-driven, not a fixed delay).
         */
        @Volatile
        var interventionActive: Boolean = false
    }

    /** Debounces repeated events for the same still-foreground app. */
    private var lastPackageName: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Never intervene on Vanya itself — otherwise opening Vanya to
        // resolve an intervention would immediately trigger another one.
        if (pkg == packageName) return

        // Debounce: Android can fire several WINDOW_STATE_CHANGED events
        // for windows within the same app (dialogs, fragments, etc.) — only
        // act when the foreground *package* actually changes.
        if (pkg == lastPackageName) return
        lastPackageName = pkg
        VanyaNativeStore.setLastForegroundPackage(this, pkg)

        // Already showing an intervention (for this or another app) —
        // don't stack a second one on top.
        if (interventionActive) return

        if (!VanyaNativeStore.isProtected(this, pkg)) return
        if (VanyaNativeStore.hasValidTemporaryAccess(this, pkg)) return

        // Without "display over other apps", a background service starting
        // an Activity may be blocked by the OS on modern Android — rather
        // than silently failing or crashing, just skip. The permission
        // onboarding/dev screen is what asks the user to grant this.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) return

        interventionActive = true
        val intent = Intent(this, InterventionActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(InterventionActivity.EXTRA_PROTECTED_PACKAGE_NAME, pkg)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        // Required override — accessibility services get no useful signal
        // here for this use case (it fires when the service itself is
        // being interrupted by the system, not on any content change).
    }
}
