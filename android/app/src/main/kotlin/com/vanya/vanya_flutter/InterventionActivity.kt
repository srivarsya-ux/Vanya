package com.vanya.vanya_flutter

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * The Activity [VanyaAccessibilityService] launches on top of a protected
 * app — a real Activity switch (not a floating `WindowManager` overlay),
 * which is what "Display over other apps" actually needs to be granted
 * for on modern Android when starting an activity from a background
 * service context. Hosts a full Flutter engine showing only the
 * intervention route; the triggering package name is read from the
 * launch intent and handed to Dart via [VanyaChannelHandler] rather than
 * encoded into a route string.
 *
 * Deliberately thin: this class does no protected-app/temporary-access
 * logic itself (that already happened in the accessibility service before
 * it decided to start this Activity) and no reasoning (that's
 * `VanyaReasoningService` on the Dart side) — see the architecture note on
 * [VanyaAccessibilityService].
 */
class InterventionActivity : FlutterActivity() {
    companion object {
        const val EXTRA_PROTECTED_PACKAGE_NAME = "protected_package_name"

        /** Consumed once by `getPendingInterventionPackage` — see [VanyaChannelHandler]. */
        @Volatile
        var pendingPackageName: String? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingPackageName = intent.getStringExtra(EXTRA_PROTECTED_PACKAGE_NAME)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        VanyaChannelHandler.attach(this, flutterEngine)
    }

    override fun finish() {
        VanyaAccessibilityService.interventionActive = false
        super.finish()
    }

    /**
     * The system back gesture/button must not be a silent third way out of
     * an intervention — only an explicit ALLOW/ALLOW_TEMPORARY_ACCESS or
     * REDIRECT/DENY decision (routed through [VanyaChannelHandler]'s
     * `finishInterventionAllow`/`finishInterventionRedirect`) may finish
     * this Activity. Without this override, back simply pops the Activity
     * and reveals whatever protected app is still sitting underneath in
     * the task stack — a full bypass of the enforcement flow.
     */
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Intentionally consumed — no super call, no Flutter delegation.
    }
}
