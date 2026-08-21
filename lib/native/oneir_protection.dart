import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything to do with the actual app-blocking mechanism: persisting
/// which apps are protected (read by OneirAccessibilityService natively),
/// the accessibility-permission flow that mechanism depends on, the
/// graduated-by-temptation-level check-in escalation, and general app state
/// persistence (name, tasks, onboarding status) so nothing resets on
/// restart.
class OneirProtection {
  OneirProtection._();

  static const _permissionsChannel = MethodChannel('oneir/permissions');
  static const _protectionChannel = MethodChannel('oneir/protection');
  static const _prefsKey = 'protected_apps';
  static const _nameKey = 'user_name';
  static const _taskStateKey = 'widget_task_state';
  static const _onboardedKey = 'has_onboarded';
  static const _intentionKey = 'current_intention';

  /// Persists the chosen package names so OneirAccessibilityService (native,
  /// running independently of any Flutter engine) can read them via the same
  /// SharedPreferences file shared_preferences already writes to.
  static Future<void> saveProtectedApps(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, packageNames);
  }

  static Future<List<String>> loadProtectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? [];
  }

  // ---- General persistence (name, tasks, onboarding) ----

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? '';
  }

  static const _reasonKey = 'user_reason';

  /// What the user said brought them to Oneir (Why Are You Here screen) --
  /// referenced back to them later so the app visibly remembers why they're
  /// here, instead of the answer being collected and never used again.
  static Future<void> saveUserReason(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reasonKey, reason);
  }

  static Future<String> loadUserReason() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reasonKey) ?? '';
  }

  static Future<void> saveTaskState(List<bool> checked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_taskStateKey, checked.map((c) => c.toString()).toList());
  }

  static Future<List<bool>?> loadTaskState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_taskStateKey);
    if (raw == null) return null;
    return raw.map((s) => s == 'true').toList();
  }

  static const _taskListKey = 'task_list_v1';

  /// A separate, real dynamic task list (add/remove any number of tasks)
  /// for the Tasks screen -- distinct from the fixed 3-item
  /// saveTaskState/loadTaskState above, which backs Home's "Today's
  /// Adventure" preview card specifically and stays untouched.
  static Future<void> saveTaskList(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_taskListKey, jsonEncode(tasks));
  }

  static Future<List<Map<String, dynamic>>> loadTaskList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskListKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  /// The user's current stated task/goal (their "today's intention"), shown
  /// back to them by Vanya during an interruption -- e.g. "You planned to:
  /// Finish Biology." Set from the Widgets screen's first unchecked task.
  static Future<void> saveCurrentIntention(String intention) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_intentionKey, intention);
  }

  static Future<String> loadCurrentIntention() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_intentionKey) ?? '';
  }

  // ---- Graduated intervention (adaptive by temptation level) ----
  //
  // Per the Co-Keeper philosophy: low temptation = simple check-in, medium =
  // reflection/countdown, high (repeated attempts / long sessions) = the
  // full Co-Keeper gate. This tracks same-day attempt counts per app as the
  // signal for which tier to show; InterruptionActivity reads the count via
  // recordAndGetAttemptCount() each time it's launched.

  static String _attemptKeyFor(String packageName) {
    final today = DateTime.now();
    final dateStamp = '${today.year}-${today.month}-${today.day}';
    return 'attempts_${dateStamp}_$packageName';
  }

  /// Increments today's attempt count for this package and returns the new
  /// total -- call once per interruption, right when it's shown.
  static Future<int> recordAndGetAttemptCount(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _attemptKeyFor(packageName);
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return next;
  }

  /// Opens Android's accessibility settings screen so the user can enable
  /// OneirAccessibilityService -- there's no direct "request" API for
  /// accessibility services the way there is for overlay/notifications;
  /// the user has to flip it on themselves in Settings.
  static Future<void> openAccessibilitySettings() async {
    try {
      await _permissionsChannel.invokeMethod('openAccessibilitySettings');
    } on PlatformException {
      // no-op on platforms without this channel (web/desktop preview)
    } on MissingPluginException {
      // no-op -- there's no real Settings app to open outside Android
    }
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      final result = await _permissionsChannel.invokeMethod<bool>('hasAccessibilityPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // No native handler on this platform (web/desktop preview) -- there's
      // no real accessibility service to check, so pass through rather than
      // trapping the user here forever, same reasoning as
      // OneirPermissions._invoke.
      return true;
    }
  }

  /// Called from the interruption screen (lib/interruption/interruption_main.dart)
  /// to send the user to their real home screen instead of back into the
  /// protected app.
  static Future<void> returnHome() async {
    try {
      await _protectionChannel.invokeMethod('returnHome');
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op (e.g. running outside InterruptionActivity's engine)
    }
  }

  static String _snoozeKeyFor(String packageName) => 'snoozed_until_$packageName';

  /// Records that this package should NOT re-trigger an intervention
  /// until [DateTime.now() + duration] -- backs the "Start 5 min break"
  /// action's real behavior: return home now, and give the user genuine
  /// breathing room before Vanya asks again.
  ///
  /// HONEST GAP: this only writes the flag. OneirAccessibilityService
  /// (the native Kotlin side) needs one added check -- before launching
  /// InterruptionActivity, read this same SharedPreferences key and skip
  /// the trigger if still snoozed -- to actually suppress the interruption
  /// while snoozed. That one native check isn't wired in this pass; until
  /// it is, this method's write is a foundation the native service can
  /// read, not yet an enforced suppression on its own.
  static Future<void> startShortBreakSnooze(String packageName, {Duration duration = const Duration(minutes: 5)}) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt(_snoozeKeyFor(packageName), until);
  }

  static Future<bool> isSnoozed(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_snoozeKeyFor(packageName));
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  /// Dismisses the interruption screen and reveals the protected app
  /// underneath it -- used for "Go Anyway" and for "Continue" once a
  /// Co-Keeper request has been approved.
  static Future<void> returnToOpenedApp() async {
    try {
      await _protectionChannel.invokeMethod('returnToOpenedApp');
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op
    }
  }
}
