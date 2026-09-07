import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vanya's type system — editorial, not startup-bold.
///
/// SwiftUI's version used the system serif ("New York") for display/title
/// text, free from the OS. Flutter/Android has no equivalent bundled serif,
/// so this pairs two Google Fonts instead:
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

  static TextStyle get display => GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: 0.1,
      );

  static TextStyle get title => GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get bodyEmphasized => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get secondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
      );

  static TextStyle get control => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  static TextStyle get footnote => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );
}
