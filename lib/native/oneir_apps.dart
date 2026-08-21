import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class InstalledApp {
  final String label;
  final String packageName;
  final Uint8List? iconBytes;

  const InstalledApp({required this.label, required this.packageName, this.iconBytes});
}

/// Queries the phone's actually-installed, launchable apps via
/// PackageManager (native side: MainActivity.kt's "oneir/apps" channel)
/// instead of relying on a hardcoded list.
class OneirApps {
  OneirApps._();

  static const _channel = MethodChannel('oneir/apps');

  /// Returns an empty list (rather than throwing) on platforms with no
  /// native implementation -- e.g. web/desktop preview -- so callers can
  /// fall back to a small hardcoded list for those cases.
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return [];
      return result.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map);
        final iconB64 = map['icon'] as String?;
        return InstalledApp(
          label: map['label'] as String? ?? map['packageName'] as String,
          packageName: map['packageName'] as String,
          iconBytes: iconB64 != null ? base64Decode(iconB64) : null,
        );
      }).toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }
}
