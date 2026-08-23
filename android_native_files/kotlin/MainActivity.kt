package com.oneir.app

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Handles the real OS-level permission requests that the Flutter side's
 * permission screens (lib/screens/permission_screens.dart) call into via
 * the "oneir/permissions" MethodChannel. Each request opens the correct
 * system settings screen and reports back whether the permission ended up
 * granted once the user returns to the app.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "oneir/permissions"
    private val overlayRequestCode = 5001
    private val notificationRequestCode = 5002

    private var pendingOverlayResult: MethodChannel.Result? = null
    private var pendingNotificationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> requestOverlayPermission(result)
                "requestNotificationPermission" -> requestNotificationPermission(result)
                "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                "hasNotificationPermission" -> result.success(hasNotificationPermission())
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "hasAccessibilityPermission" -> result.success(isAccessibilityServiceEnabled())
                "openUsageAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "hasUsageAccessPermission" -> result.success(hasUsageAccessPermission())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oneir/apps").setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> result.success(getInstalledLaunchableApps())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Returns every app the user can actually launch (has a launcher icon),
     * excluding Oneir itself, as a list of {label, packageName, icon} maps --
     * icon is a base64-encoded PNG of the app's real launcher icon so the
     * Protected Apps screen can show it directly instead of a generic glyph.
     */
    private fun getInstalledLaunchableApps(): List<Map<String, String>> {
        val pm = packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolvedApps = pm.queryIntentActivities(launcherIntent, 0)

        return resolvedApps
            .mapNotNull { it.activityInfo?.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != packageName }
            .mapNotNull { appInfo ->
                try {
                    mapOf(
                        "label" to pm.getApplicationLabel(appInfo).toString(),
                        "packageName" to appInfo.packageName,
                        "icon" to drawableToBase64(pm.getApplicationIcon(appInfo))
                    )
                } catch (e: Exception) {
                    null
                }
            }
            .sortedBy { it["label"] }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.NO_WRAP)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = "$packageName/${packageName}.OneirAccessibilityService"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(":").any { it.equals(expectedComponent, ignoreCase = true) }
    }

    /// Standard Android check: Usage Access has no direct "is granted"
    /// query, so this asks AppOpsManager whether the OP_GET_USAGE_STATS
    /// operation is allowed for this app -- the conventional way every
    /// Android app checks this permission, since there's no
    /// checkSelfPermission() equivalent for it.
    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Settings.canDrawOverlays(this)) {
            result.success(true)
            return
        }
        pendingOverlayResult = result
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        startActivityForResult(intent, overlayRequestCode)
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pendingNotificationResult = result
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), notificationRequestCode)
        } else {
            // Below Android 13, notification permission is granted at install time.
            result.success(true)
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == overlayRequestCode) {
            pendingOverlayResult?.success(Settings.canDrawOverlays(this))
            pendingOverlayResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            pendingNotificationResult?.success(granted)
            pendingNotificationResult = null
        }
    }
}
