import 'package:flutter/material.dart';

/// Vanya's type system — editorial, not startup-bold.
///
/// SwiftUI's version used the system serif ("New York") for display/title
/// text, free from the OS. Flutter/Android has no equivalent bundled serif,
/// so this pairs two fonts instead, bundled as local assets (see
/// `assets/fonts/` and `pubspec.yaml`) rather than fetched over the network
/// at runtime:
/// - **Fraunces** for display/title/section-title — a warm, slightly
///   storybook serif with real personality at large sizes.
/// - **Inter** for body/secondary/control/caption — clean and highly
///   legible at small sizes, renders well across Android devices.
///
/// Every style is built from a base `TextStyle` and scaled with
/// [MediaQuery]'s text scaler by the widgets that use it (Flutter applies
/// text scaling automatically via `Theme`/`MediaQuery`, so nothing here
/// hardcodes an unscalable pixel size beyond the base value).
class VanyaTypography {
  const VanyaTypography._();

  static TextStyle get display => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 34,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: 0.1,
      );

  static TextStyle get title => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get bodyEmphasized => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get secondary => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
      );

  static TextStyle get control => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  static TextStyle get footnote => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );
}
