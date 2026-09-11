import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one long-lived model behind the whole onboarding flow. Every screen
/// reads from and writes into this instead of threading a dozen callbacks
/// through [OnboardingFlow] — that pattern was fine for 5 screens, not for
/// the ~12 this flow now has.
///
/// Every mutation persists to [SharedPreferences] as JSON, and the current
/// values are loaded back on construction — so force-stopping the app or
/// leaving onboarding mid-flow and coming back resumes exactly where the
/// user left off, per the "never make users repeat completed setup"
/// requirement. This is intentionally a plain [ChangeNotifier] + JSON blob
/// rather than a database: onboarding progress is small, single-user,
/// on-device state, not something that needs querying or relations.
class OnboardingState extends ChangeNotifier {
  OnboardingState._();

  static const _prefsKey = 'onboarding_state_v1';

  String? userName;
  final Set<String> intentions = {};
  final Set<String> moments = {};
  String? promiseDuration;
  bool promiseMade = false;
  final Set<String> protectedAppPackages = {};

  bool usageAccessGranted = false;
  bool overlayGranted = false;
  bool notificationsGranted = false;
  bool batteryExemptionGranted = false;
  bool accessibilityEnabled = false;

  /// The furthest page index the user has reached, so the progress
  /// indicator and resume-on-relaunch logic have a single source of truth.
  int currentStep = 0;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  static Future<OnboardingState> load() async {
    final state = OnboardingState._();
    await state._load();
    return state;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        userName = json['userName'] as String?;
        intentions.addAll((json['intentions'] as List?)?.cast<String>() ?? const []);
        moments.addAll((json['moments'] as List?)?.cast<String>() ?? const []);
        promiseDuration = json['promiseDuration'] as String?;
        promiseMade = json['promiseMade'] as bool? ?? false;
        protectedAppPackages.addAll(
          (json['protectedAppPackages'] as List?)?.cast<String>() ?? const [],
        );
        usageAccessGranted = json['usageAccessGranted'] as bool? ?? false;
        overlayGranted = json['overlayGranted'] as bool? ?? false;
        notificationsGranted = json['notificationsGranted'] as bool? ?? false;
        batteryExemptionGranted = json['batteryExemptionGranted'] as bool? ?? false;
        accessibilityEnabled = json['accessibilityEnabled'] as bool? ?? false;
        currentStep = json['currentStep'] as int? ?? 0;
      } catch (_) {
        // Corrupt/old-shape prefs blob — start fresh rather than crash.
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'userName': userName,
        'intentions': intentions.toList(),
        'moments': moments.toList(),
        'promiseDuration': promiseDuration,
        'promiseMade': promiseMade,
        'protectedAppPackages': protectedAppPackages.toList(),
        'usageAccessGranted': usageAccessGranted,
        'overlayGranted': overlayGranted,
        'notificationsGranted': notificationsGranted,
        'batteryExemptionGranted': batteryExemptionGranted,
        'accessibilityEnabled': accessibilityEnabled,
        'currentStep': currentStep,
      }),
    );
  }

  /// Every write is chained onto the previous one instead of fired off
  /// independently — `SharedPreferences.setString` on Android uses
  /// `apply()`, an async, best-effort disk write. `am force-stop` (and, in
  /// principle, the OS reclaiming memory) can kill the process before a
  /// loose fire-and-forget write like the old version of this method used
  /// has actually reached disk, silently losing the last few onboarding
  /// steps. [flush] lets callers that are about to do something the user
  /// might immediately background or kill the app after (advancing to a
  /// new page, in practice) wait for every write queued so far to actually
  /// land before proceeding.
  Future<void> _pendingWrite = Future.value();

  void _commit() {
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) => _persist());
  }

  /// Resolves once every state change committed so far has been written to
  /// disk. Await this before any point where the app might reasonably be
  /// backgrounded or killed right after — page navigation, in particular.
  Future<void> flush() => _pendingWrite;

  void setUserName(String value) {
    userName = value.trim();
    _commit();
  }

  void toggleIntention(String value) {
    if (!intentions.remove(value)) intentions.add(value);
    _commit();
  }

  void toggleMoment(String value) {
    if (!moments.remove(value)) moments.add(value);
    _commit();
  }

  void setPromiseDuration(String value) {
    promiseDuration = value;
    _commit();
  }

  void setPromiseMade(bool value) {
    promiseMade = value;
    _commit();
  }

  void toggleProtectedApp(String packageName) {
    if (!protectedAppPackages.remove(packageName)) {
      protectedAppPackages.add(packageName);
    }
    _commit();
  }

  void setPermission({
    bool? usageAccess,
    bool? overlay,
    bool? notifications,
    bool? batteryExemption,
    bool? accessibility,
  }) {
    if (usageAccess != null) usageAccessGranted = usageAccess;
    if (overlay != null) overlayGranted = overlay;
    if (notifications != null) notificationsGranted = notifications;
    if (batteryExemption != null) batteryExemptionGranted = batteryExemption;
    if (accessibility != null) accessibilityEnabled = accessibility;
    _commit();
  }

  void setCurrentStep(int step) {
    if (step <= currentStep) return;
    currentStep = step;
    _commit();
  }
}
