import 'package:flutter/services.dart';

/// Talks to the native Android side (android/.../MainActivity.kt) over a
/// MethodChannel to request and check the two real OS permissions Oneir
/// needs: drawing over other apps (to show Vanya before a blocked app opens)
/// and posting notifications (to remind/encourage the user).
///
/// On non-Android platforms (iOS, web, desktop -- e.g. while iterating in
/// this sandbox or on `flutter run -d web-server`) every call safely
/// resolves to `false` rather than throwing, since there's no native
/// implementation wired up there.
class OneirPermissions {
  OneirPermissions._();

  static const _channel = MethodChannel('oneir/permissions');

  static Future<bool> requestOverlayPermission() => _invoke('requestOverlayPermission');

  static Future<bool> requestNotificationPermission() => _invoke('requestNotificationPermission');

  static Future<bool> hasOverlayPermission() => _invoke('hasOverlayPermission');

  static Future<bool> hasNotificationPermission() => _invoke('hasNotificationPermission');

  /// Usage Access -- lets Oneir see which app is currently in the
  /// foreground (via UsageStatsManager) so it knows a protected app was
  /// just opened. There's no "request" dialog for this permission the way
  /// there is for overlay/notifications; like Accessibility, the user has
  /// to flip it on themselves in a real Settings screen -- this opens that
  /// screen (ACTION_USAGE_ACCESS_SETTINGS) rather than pretending to grant
  /// it directly.
  static Future<bool> openUsageAccessSettings() => _invoke('openUsageAccessSettings');

  static Future<bool> hasUsageAccessPermission() => _invoke('hasUsageAccessPermission');

  static Future<bool> _invoke(String method) async {
    try {
      final result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } on MissingPluginException {
      // No native handler on this platform (web/desktop preview) -- there's
      // no real OS permission to grant or deny here, so treat it as a
      // pass-through rather than a decline. Returning false here would trap
      // the user on every permission screen forever while previewing on
      // `flutter run -d chrome`, since nothing on web could ever "grant" it.
      return true;
    } on PlatformException {
      return false;
    }
  }
}
