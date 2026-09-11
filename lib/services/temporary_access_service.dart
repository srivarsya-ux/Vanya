import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/temporary_access_grant.dart';
import '../native/vanya_permissions.dart';

/// Application-level bookkeeping for temporary exceptions to protected-app
/// blocking. Every grant/revoke also pushes to
/// `VanyaAccessibilityService`'s native mirror (see
/// `VanyaPermissions.syncTemporaryGrant`/`clearTemporaryGrant`), which
/// re-derives validity from the same timestamp on the Android side — so a
/// grant is authoritative by expiry time, not by whether Dart happens to
/// be running when it's checked.
class TemporaryAccessService extends ChangeNotifier {
  TemporaryAccessService._();

  static const _prefsKey = 'vanya_temporary_access_grants_v1';

  final List<TemporaryAccessGrant> _grants = [];
  List<TemporaryAccessGrant> get grants => List.unmodifiable(_grants);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> _pendingWrite = Future.value();

  static Future<TemporaryAccessService> load() async {
    final service = TemporaryAccessService._();
    await service._load();
    return service;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      for (final entry in raw) {
        try {
          _grants.add(
            TemporaryAccessGrant.fromJson(jsonDecode(entry) as Map<String, dynamic>),
          );
        } catch (_) {}
      }
    }
    _loaded = true;
    unawaited(_resyncAllNative());
  }

  /// Pushes every currently-active grant to the native mirror — covers the
  /// case where native's copy went stale (e.g. app data changed while the
  /// process wasn't running).
  Future<void> _resyncAllNative() async {
    final now = DateTime.now();
    final activeByPackage = <String, DateTime>{};
    for (final grant in _grants) {
      if (grant.isActiveAt(now)) activeByPackage[grant.packageName] = grant.expiresAt;
    }
    for (final entry in activeByPackage.entries) {
      await _syncNative(entry.key, entry.value);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _grants.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }

  void _commit() {
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) => _persist());
  }

  Future<void> flush() => _pendingWrite;

  TemporaryAccessGrant? activeGrantFor(String packageName, {DateTime? at}) {
    final moment = at ?? DateTime.now();
    for (final grant in _grants.reversed) {
      if (grant.packageName == packageName && grant.isActiveAt(moment)) {
        return grant;
      }
    }
    return null;
  }

  bool hasActiveAccess(String packageName, {DateTime? at}) =>
      activeGrantFor(packageName, at: at) != null;

  DateTime? expiryFor(String packageName) => activeGrantFor(packageName)?.expiresAt;

  Future<TemporaryAccessGrant> createGrant({
    required String packageName,
    required Duration duration,
    required String reason,
    required String source,
  }) async {
    final now = DateTime.now();
    final grant = TemporaryAccessGrant(
      id: '${now.microsecondsSinceEpoch}',
      packageName: packageName,
      grantedAt: now,
      expiresAt: now.add(duration),
      reason: reason,
      source: source,
    );
    _grants.add(grant);
    _commit();
    unawaited(_syncNative(packageName, grant.expiresAt));
    return grant;
  }

  Future<void> revoke(String grantId) async {
    final index = _grants.indexWhere((g) => g.id == grantId);
    if (index == -1) return;
    final packageName = _grants[index].packageName;
    _grants[index] = _grants[index].revoke();
    _commit();
    unawaited(_clearNative(packageName));
  }

  Future<void> _syncNative(String packageName, DateTime expiresAt) async {
    try {
      await VanyaPermissions.syncTemporaryGrant(packageName, expiresAt);
    } catch (_) {
      // Best-effort — see ProtectedAppService._syncNative for why this
      // never propagates.
    }
  }

  Future<void> _clearNative(String packageName) async {
    try {
      await VanyaPermissions.clearTemporaryGrant(packageName);
    } catch (_) {}
  }
}
