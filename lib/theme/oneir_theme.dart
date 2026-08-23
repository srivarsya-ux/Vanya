import 'package:flutter/material.dart';

/// Centralized design tokens, matching the approved Figma/React reference
/// exactly. Design reference frame is 351.7 x 715.3 logical px (matches a
/// 3x mobile Figma export / 3) — all screens scale from that.
class OneirColors {
  OneirColors._();

  // White/gray palette with periwinkle reserved exclusively for primary
  // buttons and the strongest selected states -- reverted back from the
  // warm earth-tone palette per explicit direction; nothing else in the
  // app carries color.
  static const Color background = Color(0xFFF8F8F9);
  static const Color text = Color(0xFF2F2E2E);
  static const Color textMuted = Color(0xFF4A4A4A);
  static const Color textFaint = Color(0xFF9A9A9A);
  static const Color splashWordmark = Color(0xFF464646);
  static const Color inputFill = Color(0xFFE8E8E8);
  static const Color border = Color(0xFFC7C7C7);

  // The only color in the app besides white/gray/black -- used solely for
  // primary buttons.
  static const Color accent = Color(0xFFA8A4D8); // dusty lavender, sampled from user-provided swatch

  static const Color cardNeutral = Color(0xFFF2F2F2);
  static const Color success = Color(0xFF4A4A4A); // no green -- grayscale only
}

class OneirText {
  OneirText._();

  // Plus Jakarta Sans, bundled locally as a real asset (see pubspec.yaml's
  // `fonts:` section) rather than fetched over the network via google_fonts
  // at runtime -- a runtime fetch silently falls back to the system font
  // with no error if the device/browser can't reach Google's font CDN,
  // which looks exactly like "the font never changed" even when the code
  // is completely correct. Bundling it locally removes that failure mode
  // entirely. See android_native_files/SETUP.md for the one-time step of
  // downloading the actual font files into assets/fonts/.
  static const TextStyle heading = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w600,
    fontSize: 42.67,
    letterSpacing: -0.85,
    height: 1.15,
    color: OneirColors.text,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    height: 1.6,
    color: OneirColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  );
}

/// Design reference size every screen is authored against, then scaled to
/// the real device width in [OneirScaffold].
const double kDesignWidth = 351.7;
const double kDesignHeight = 715.3;
