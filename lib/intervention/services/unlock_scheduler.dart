import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/unlock_session.dart';

/// Tracks approved-access windows per protected app and fires a callback
/// when one expires, so the caller can re-show the intervention overlay.
///
/// Sessions are persisted (SharedPreferences) so an approved window
/// survives the app process being killed and restarted -- the actual
/// re-lock enforcement on Android happens via OneirAccessibilityService
/// checking `hasActiveSession()` before deciding whether to launch the
/// interruption again (see SETUP.md for the native-side wiring this
/// still needs).
class UnlockScheduler {
  UnlockScheduler._();
  static final UnlockScheduler instance = UnlockScheduler._();

  static const _prefsKey = 'active_unlock_sessions';

  final Map<String, Timer> _timers = {};
  void Function(String packageName)? onSessionExpired;

  Future<Map<String, UnlockSession>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, UnlockSession.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _saveAll(Map<String, UnlockSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_prefsKey, encoded);
  }

  /// Starts (or replaces) an approved-access window for [packageName].
  Future<UnlockSession> startSession({
    required String packageName,
    required Duration duration,
    required String reason,
  }) async {
    final session = UnlockSession(
      packageName: packageName,
      startTime: DateTime.now(),
      allowedDuration: duration,
      reason: reason,
    );
    final all = await _loadAll();
    all[packageName] = session;
    await _saveAll(all);
    _scheduleExpiry(session);
    return session;
  }

  /// Extends an in-progress session by [extra] -- used when the user asks
  /// for a bit more time at re-lock and the AI judges the request
  /// consistent with the original stated task.
  Future<UnlockSession?> extendSession(String packageName, Duration extra) async {
    final all = await _loadAll();
    final existing = all[packageName];
    if (existing == null) return null;
    final extended = existing.extendedBy(extra);
    all[packageName] = extended;
    await _saveAll(all);
    _scheduleExpiry(extended);
    return extended;
  }

  Future<void> endSession(String packageName) async {
    final all = await _loadAll();
    all.remove(packageName);
    await _saveAll(all);
    _timers.remove(packageName)?.cancel();
  }

  Future<UnlockSession?> getSession(String packageName) async {
    final all = await _loadAll();
    return all[packageName];
  }

  Future<bool> hasActiveSession(String packageName) async {
    final session = await getSession(packageName);
    return session != null && !session.isExpired;
  }

  void _scheduleExpiry(UnlockSession session) {
    _timers.remove(session.packageName)?.cancel();
    final remaining = session.remaining;
    if (remaining == Duration.zero) {
      onSessionExpired?.call(session.packageName);
      return;
    }
    _timers[session.packageName] = Timer(remaining, () {
      onSessionExpired?.call(session.packageName);
    });
  }

  /// Call once at app startup (or when OneirAccessibilityService detects a
  /// protected app opening) to re-arm timers for any sessions that were
  /// already running before the process restarted.
  Future<void> resumePersistedTimers() async {
    final all = await _loadAll();
    for (final session in all.values) {
      if (session.isExpired) {
        onSessionExpired?.call(session.packageName);
      } else {
        _scheduleExpiry(session);
      }
    }
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
