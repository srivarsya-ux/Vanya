import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/protected_app.dart';
import '../native/vanya_permissions.dart';

/// Data/service layer for which apps the user has chosen for Vanya to help
/// with. Every change also pushes the current protected-package set to
/// `VanyaAccessibilityService`'s native mirror (see
/// `VanyaPermissions.syncProtectedApps`) so enforcement reflects this
/// service's state without the accessibility service needing a live Dart
/// engine to ask.
class ProtectedAppService extends ChangeNotifier {
  ProtectedAppService._();

  static const _prefsKey = 'vanya_protected_apps_v1';

  final List<ProtectedApp> _apps = [];
  List<ProtectedApp> get apps => List.unmodifiable(_apps);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> _pendingWrite = Future.value();

  static Future<ProtectedAppService> load() async {
    final service = ProtectedAppService._();
    await service._load();
    return service;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      for (final entry in raw) {
        try {
          _apps.add(ProtectedApp.fromJson(jsonDecode(entry) as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    _loaded = true;
    unawaited(_syncNative());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _apps.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  void _commit() {
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) => _persist()).then((_) => _syncNative());
  }

  Future<void> _syncNative() async {
    try {
      final protectedPackages = _apps
          .where((a) => a.isProtected)
          .map((a) => a.packageName)
          .toSet();
      await VanyaPermissions.syncProtectedApps(protectedPackages);
    } catch (_) {
      // Best-effort — enforcement staying slightly stale is far better
      // than a channel hiccup breaking the Dart-side data flow.
    }
  }

  Future<void> flush() => _pendingWrite;

  Future<void> addApp(ProtectedApp app) async {
    if (_apps.any((a) => a.packageName == app.packageName)) return;
    _apps.add(app);
    _commit();
  }

  Future<void> removeApp(String packageName) async {
    _apps.removeWhere((a) => a.packageName == packageName);
    _commit();
  }

  Future<void> setProtected(String packageName, bool protected) async {
    final index = _apps.indexWhere((a) => a.packageName == packageName);
    if (index == -1) return;
    _apps[index] = _apps[index].copyWith(isProtected: protected);
    _commit();
  }

  bool isProtected(String packageName) {
    for (final app in _apps) {
      if (app.packageName == packageName) return app.isProtected;
    }
    return false;
  }
}
