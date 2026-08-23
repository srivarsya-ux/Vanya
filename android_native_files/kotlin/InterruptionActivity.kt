package com.oneir.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A separate Activity (not a raw WindowManager overlay) that OneirAccessibilityService
 * launches on top of whatever protected app the user just opened. Using a real
 * Activity -- rather than trying to draw a Flutter view directly from the
 * background service -- keeps this simple and lets it be a completely normal
 * Flutter screen, just with its own Dart entrypoint (`interruptionMain`,
 * defined in lib/interruption/interruption_main.dart) so it doesn't have to
 * boot the entire app's onboarding flow just to show one screen.
 */
class InterruptionActivity : FlutterActivity() {

    companion object {
        const val EXTRA_PACKAGE_NAME = "package_name"
    }

    override fun getDartEntrypointFunctionName(): String = "interruptionMain"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Helps this feel like an interruption layered on top, not a fresh app.
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
    }

    override fun getDartEntrypointArgs(): List<String> {
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        return listOf(packageName)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oneir/protection").setMethodCallHandler { call, result ->
            when (call.method) {
                "returnHome" -> {
                    // Sends the user to their real home screen rather than back
                    // into the protected app they just tried to open.
                    moveTaskToBack(true)
                    finish()
                    result.success(null)
                }
                "returnToOpenedApp" -> {
                    // Just dismiss this Activity -- the protected app it was
                    // launched on top of is still there underneath, so simply
                    // finishing reveals it again (used for "Go Anyway" and
                    // "Continue" after Co-Keeper approval).
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
