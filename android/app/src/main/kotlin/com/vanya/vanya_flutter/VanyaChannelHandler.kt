package com.vanya.vanya_flutter

import android.app.Activity
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * All `com.vanya.vanya_flutter/permissions` channel methods in one place,
 * shared by [MainActivity] and [InterventionActivity] — permission
 * checks/settings shortcuts (existing, from the onboarding phase) plus the
 * enforcement-layer additions: syncing [VanyaNativeStore], reading the
 * package that triggered an intervention, and resolving a finished
 * intervention's task-stack outcome. Nothing AI- or reasoning-related
 * lives here; this only bridges Android state and Android actions.
 */
object VanyaChannelHandler {
    const val CHANNEL_NAME = "com.vanya.vanya_flutter/permissions"

    fun attach(activity: Activity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result -> handle(activity, call, result) }
    }

    private fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listInstalledApps" -> result.success(listInstalledApps(activity))
            "hasUsageAccess" -> result.success(hasUsageAccess(activity))
            "openUsageAccessSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                result.success(null)
            }
            "canDrawOverlays" -> result.success(canDrawOverlays(activity))
            "openOverlaySettings" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}"),
                )
                activity.startActivity(intent)
                result.success(null)
            }
            "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations(activity))
            "requestIgnoreBatteryOptimizations" -> {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${activity.packageName}"),
                )
                activity.startActivity(intent)
                result.success(null)
            }
            "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled(activity))
            "openAccessibilitySettings" -> {
                activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(null)
            }

            // --- Enforcement layer ---
            "syncProtectedApps" -> {
                @Suppress("UNCHECKED_CAST")
                val packages = (call.arguments as? List<String>)?.toSet() ?: emptySet()
                VanyaNativeStore.setProtectedPackages(activity, packages)
                result.success(null)
            }
            "syncTemporaryGrant" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as Map<String, Any>
                val pkg = args["packageName"] as String
                val expiresAtMillis = (args["expiresAtMillis"] as Number).toLong()
                VanyaNativeStore.setTemporaryGrant(activity, pkg, expiresAtMillis)
                result.success(null)
            }
            "clearTemporaryGrant" -> {
                val pkg = call.arguments as String
                VanyaNativeStore.clearTemporaryGrant(activity, pkg)
                result.success(null)
            }
            "getLastDetectedForegroundPackage" -> {
                result.success(VanyaNativeStore.getLastForegroundPackage(activity))
            }
            "getPendingInterventionPackage" -> {
                val pkg = InterventionActivity.pendingPackageName
                InterventionActivity.pendingPackageName = null
                result.success(pkg)
            }
            "finishInterventionAllow" -> {
                // Reveals the protected app underneath — this Activity was
                // started on top of it with FLAG_ACTIVITY_NEW_TASK, so
                // finishing it (without touching the home stack) surfaces
                // whatever was frontmost immediately before.
                activity.finish()
                result.success(null)
            }
            "finishInterventionRedirect" -> {
                // The protected app must not remain accessible — go to the
                // device home screen instead of just finishing (which would
                // reveal the protected app again).
                val home = Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_HOME)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity.startActivity(home)
                activity.finish()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun listInstalledApps(activity: Activity): List<Map<String, String>> {
        val pm = activity.packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved = pm.queryIntentActivities(launcherIntent, PackageManager.MATCH_ALL)
        val seen = HashSet<String>()
        val apps = mutableListOf<Map<String, String>>()
        for (info in resolved) {
            val pkg = info.activityInfo.packageName
            if (pkg == activity.packageName || !seen.add(pkg)) continue
            val label = info.loadLabel(pm).toString()
            apps.add(mapOf("packageName" to pkg, "label" to label))
        }
        apps.sortBy { it["label"] }
        return apps
    }

    private fun hasUsageAccess(activity: Activity): Boolean {
        val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun canDrawOverlays(activity: Activity): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(activity)

    private fun isIgnoringBatteryOptimizations(activity: Activity): Boolean {
        val powerManager = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(activity.packageName)
    }

    private fun isAccessibilityServiceEnabled(activity: Activity): Boolean {
        val expected = ComponentName(activity, VanyaAccessibilityService::class.java).flattenToString()
        val enabledServices = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }
}
