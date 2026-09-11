package com.vanya.vanya_flutter

import android.content.Context

/**
 * A minimal, native-owned mirror of two pieces of Dart-managed state:
 * which packages are protected, and which have a currently-valid
 * temporary-access grant. This is *not* a second temporary-access system
 * — Dart's `ProtectedAppService`/`TemporaryAccessService` remain the rich,
 * authoritative source (display names, reasons, full grant history);
 * this store only keeps the bare minimum [VanyaAccessibilityService]
 * needs to make a fast, local "should I intervene right now?" decision
 * without spinning up a Flutter engine on every foreground-app change.
 *
 * Dart pushes updates here via the platform channel every time either
 * service's state actually changes (see `vanya_native_bridge.dart`), and
 * expiry is checked against `System.currentTimeMillis()` here natively —
 * so a grant is authoritative by timestamp, not by whether any Dart code
 * happens to be running.
 */
object VanyaNativeStore {
    private const val PREFS_NAME = "vanya_native_state"
    private const val KEY_PROTECTED_PACKAGES = "protected_packages"
    private const val KEY_GRANTS = "temporary_grants"
    private const val KEY_LAST_FOREGROUND_PACKAGE = "last_foreground_package"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setProtectedPackages(context: Context, packages: Set<String>) {
        prefs(context).edit().putStringSet(KEY_PROTECTED_PACKAGES, packages).apply()
    }

    fun isProtected(context: Context, packageName: String): Boolean {
        return prefs(context).getStringSet(KEY_PROTECTED_PACKAGES, emptySet())
            ?.contains(packageName) == true
    }

    fun setTemporaryGrant(context: Context, packageName: String, expiresAtMillis: Long) {
        val grants = readGrants(context).toMutableMap()
        grants[packageName] = expiresAtMillis
        writeGrants(context, grants)
    }

    fun clearTemporaryGrant(context: Context, packageName: String) {
        val grants = readGrants(context).toMutableMap()
        if (grants.remove(packageName) != null) writeGrants(context, grants)
    }

    /** Authoritative by timestamp — never assumes a grant is valid just because it exists. */
    fun hasValidTemporaryAccess(context: Context, packageName: String): Boolean {
        val expiresAt = readGrants(context)[packageName] ?: return false
        return System.currentTimeMillis() < expiresAt
    }

    fun setLastForegroundPackage(context: Context, packageName: String) {
        prefs(context).edit().putString(KEY_LAST_FOREGROUND_PACKAGE, packageName).apply()
    }

    fun getLastForegroundPackage(context: Context): String? =
        prefs(context).getString(KEY_LAST_FOREGROUND_PACKAGE, null)

    /** Stored as `pkg1:millis1,pkg2:millis2` — simple, no JSON dependency needed. */
    private fun readGrants(context: Context): Map<String, Long> {
        val raw = prefs(context).getString(KEY_GRANTS, null)
        if (raw.isNullOrEmpty()) return emptyMap()
        return raw.split(",").mapNotNull { entry ->
            val parts = entry.split(":")
            val millis = parts.getOrNull(1)?.toLongOrNull()
            if (parts.size == 2 && millis != null) parts[0] to millis else null
        }.toMap()
    }

    private fun writeGrants(context: Context, grants: Map<String, Long>) {
        val raw = grants.entries.joinToString(",") { "${it.key}:${it.value}" }
        prefs(context).edit().putString(KEY_GRANTS, raw).apply()
    }
}
