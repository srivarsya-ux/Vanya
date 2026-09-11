import 'package:flutter/services.dart';

/// A single installed, launchable app — enough to render a row in the
/// protected-apps picker. No icon bytes in v1 (see the onboarding plan):
/// keeping the native surface small for now, upgradeable later.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.label});

  final String packageName;
  final String label;

  factory InstalledApp.fromMap(Map<Object?, Object?> map) {
    return InstalledApp(
      packageName: map['packageName'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }
}

/// Dart-side wrapper around the `com.vanya.vanya_flutter/permissions`
/// MethodChannel implemented in `MainActivity.kt`. Covers the Android
/// capabilities that aren't standard runtime permissions — Usage Access,
/// drawing overlays, battery-optimization exemption, and the Accessibility
/// Service toggle — all of which only exist as Settings deep-links plus a
/// separate "is it actually on" check, not a `requestPermission()` dialog.
class VanyaPermissions {
  const VanyaPermissions._();

  static const MethodChannel _channel = MethodChannel(
    'com.vanya.vanya_flutter/permissions',
  );

  static Future<List<InstalledApp>> listInstalledApps() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'listInstalledApps',
    );
    if (result == null) return const [];
    return result
        .cast<Map<Object?, Object?>>()
        .map(InstalledApp.fromMap)
        .toList();
  }

  static Future<bool> hasUsageAccess() async {
    return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
  }

  static Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod('openUsageAccessSettings');
  }

  static Future<bool> canDrawOverlays() async {
    return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
  }

  static Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    return await _channel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations',
        ) ??
        false;
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    return await _channel.invokeMethod<bool>(
          'isAccessibilityServiceEnabled',
        ) ??
        false;
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  // --- Enforcement layer: mirrors ProtectedAppService/TemporaryAccessService
  // into VanyaAccessibilityService's lightweight native store, and bridges
  // an Android-launched intervention back to the right task-stack outcome.
  // See VanyaChannelHandler.kt for the native side of each of these.

  /// Pushes the full current protected-package set — called by
  /// `ProtectedAppService` on every change, not incrementally, so the
  /// native mirror can never drift out of sync from a missed update.
  static Future<void> syncProtectedApps(Set<String> packageNames) async {
    await _channel.invokeMethod('syncProtectedApps', packageNames.toList());
  }

  static Future<void> syncTemporaryGrant(
    String packageName,
    DateTime expiresAt,
  ) async {
    await _channel.invokeMethod('syncTemporaryGrant', {
      'packageName': packageName,
      'expiresAtMillis': expiresAt.millisecondsSinceEpoch,
    });
  }

  static Future<void> clearTemporaryGrant(String packageName) async {
    await _channel.invokeMethod('clearTemporaryGrant', packageName);
  }

  /// The last foreground package [VanyaAccessibilityService] observed —
  /// for the development test screen, not used by any decision logic.
  static Future<String?> getLastDetectedForegroundPackage() async {
    return _channel.invokeMethod<String>('getLastDetectedForegroundPackage');
  }

  /// Non-null only when this Flutter engine was started by
  /// `InterventionActivity` — the package name that triggered it. Consumed
  /// once: the native side clears it after returning it.
  static Future<String?> getPendingInterventionPackage() async {
    return _channel.invokeMethod<String>('getPendingInterventionPackage');
  }

  /// Finishes an Android-launched intervention for ALLOW /
  /// ALLOW_TEMPORARY_ACCESS — reveals the protected app underneath.
  static Future<void> finishInterventionAllow() async {
    await _channel.invokeMethod('finishInterventionAllow');
  }

  /// Finishes an Android-launched intervention for REDIRECT/DENY — sends
  /// the user to the device home screen instead of back into the app.
  static Future<void> finishInterventionRedirect() async {
    await _channel.invokeMethod('finishInterventionRedirect');
  }
}
