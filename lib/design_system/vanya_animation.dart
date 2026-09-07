import 'package:flutter/material.dart';

/// Vanya's motion language: physical, calm, and always willing to get out of
/// the way for reduced-motion preferences. No bounce-for-its-own-sake, no
/// particle effects — motion communicates that something is alive, not that
/// something happened.
///
/// SwiftUI's `.spring(response:dampingFraction:)` has no 1:1 Flutter widget
/// equivalent, so the same physical presets are expressed as
/// [SpringDescription]s (from `package:flutter/physics.dart` — no extra
/// dependency needed) for use with an [AnimationController] via
/// `controller.animateWith(SpringSimulation(...))`. Curve-based durations are
/// provided too, for the common case of driving an implicit animation
/// (`AnimatedContainer`, `AnimatedSwitcher`) instead.
class VanyaAnimation {
  const VanyaAnimation._();

  /// The default spring for most state changes (selection, layout changes
  /// within a screen).
  static const gentle = SpringDescription(mass: 1, stiffness: 180, damping: 24);

  /// A snappier spring for small, frequent interactions (toggles, taps).
  static const quick = SpringDescription(mass: 1, stiffness: 300, damping: 26);

  /// A slow, wide spring for full-screen transitions (entering Focus,
  /// completing an intervention).
  static const unfold = SpringDescription(mass: 1, stiffness: 90, damping: 20);

  /// Curve-based equivalents for implicit animations.
  static const Duration gentleDuration = Duration(milliseconds: 420);
  static const Duration quickDuration = Duration(milliseconds: 260);
  static const Duration unfoldDuration = Duration(milliseconds: 620);
  static const Duration fadeDuration = Duration(milliseconds: 250);

  static const Curve gentleCurve = Curves.easeOutCubic;
  static const Curve quickCurve = Curves.easeOut;
  static const Curve unfoldCurve = Curves.easeInOutCubic;

  /// A slow, non-settling ease for ambient, looping motion (Vanya's idle
  /// breathing, environmental drift). Deliberately not a spring — springs
  /// settle, this shouldn't.
  static const Duration breatheDuration = Duration(milliseconds: 3200);
  static const Curve breatheCurve = Curves.easeInOut;
}

/// Whether the platform has requested reduced motion — the Flutter
/// equivalent of iOS's `UIAccessibility.isReduceMotionEnabled`, reflecting
/// both iOS Reduce Motion and Android's "Remove animations" setting.
/// Prefer this over hardcoding an animation everywhere idle/looping motion
/// is considered.
extension VanyaReduceMotion on BuildContext {
  bool get vanyaReduceMotion => MediaQuery.of(this).disableAnimations;
}
