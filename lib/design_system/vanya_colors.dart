import 'package:flutter/material.dart';

/// Vanya's color palette, ported 1:1 (same hex values) from the SwiftUI
/// `VanyaColors` enum. Warm, paper-like, low-saturation on purpose — Vanya's
/// fur is the dominant character color, so the interface itself stays
/// quiet, and accent color is spent sparingly.
///
/// Registered on [ThemeData] as a [ThemeExtension] so screens read colors via
/// `context.vanyaColors.xyz`, the same way SwiftUI views read
/// `VanyaColors.xyz` directly — the extension is what makes a single value
/// resolve differently in light vs. dark, mirroring the Swift
/// `Color(light:dark:)` helper.
@immutable
class VanyaColors extends ThemeExtension<VanyaColors> {
  const VanyaColors({
    required this.background,
    required this.surface,
    required this.surfaceDeep,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.accent,
    required this.accentMuted,
    required this.gentle,
    required this.gentleMuted,
    required this.notice,
    required this.furBase,
    required this.furShadow,
    required this.furHighlight,
    required this.furEarInner,
    required this.furEyes,
    required this.furNose,
    required this.glassTint,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
    required this.separator,
  });

  final Color background;
  final Color surface;
  final Color surfaceDeep;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;

  final Color accent;
  final Color accentMuted;
  final Color gentle;
  final Color gentleMuted;
  final Color notice;

  final Color furBase;
  final Color furShadow;
  final Color furHighlight;
  final Color furEarInner;
  final Color furEyes;
  final Color furNose;

  final Color glassTint;
  final Color glassBorder;
  final Color glassHighlight;
  final Color glassShadow;

  final Color separator;

  static const light = VanyaColors(
    background: Color(0xFFFBF5EA),
    surface: Color(0xFFF4EBDA),
    surfaceDeep: Color(0xFFEDE0C9),
    textPrimary: Color(0xFF2B2318),
    textSecondary: Color(0xFF6E6152),
    textTertiary: Color(0xFF9C9080),
    textOnAccent: Color(0xFFFBF5EA),
    accent: Color(0xFFBF7A4A),
    accentMuted: Color(0x24BF7A4A), // ~14% opacity
    gentle: Color(0xFF7C8F6B),
    gentleMuted: Color(0x247C8F6B),
    notice: Color(0xFFB08A3E),
    furBase: Color(0xFFDBB98C),
    furShadow: Color(0xFFB08D62),
    furHighlight: Color(0xFFEED9B7),
    furEarInner: Color(0xFFE7AE9C),
    furEyes: Color(0xFF4A3626),
    furNose: Color(0xFF8C5A4A),
    glassTint: Color(0x8CFFF9EE), // ~55% opacity
    glassBorder: Color(0x80FFFFFF), // 50% white
    glassHighlight: Color(0x59FFFFFF), // ~35% white
    glassShadow: Color(0x1A2B2318), // ~10% dark
    separator: Color(0x142B2318), // ~8% dark
  );

  static const dark = VanyaColors(
    background: Color(0xFF1E1A16),
    surface: Color(0xFF28221C),
    surfaceDeep: Color(0xFF171310),
    textPrimary: Color(0xFFF4ECDF),
    textSecondary: Color(0xFFB9AC98),
    textTertiary: Color(0xFF8A7E6E),
    textOnAccent: Color(0xFFFBF5EA),
    accent: Color(0xFFD79A6C),
    accentMuted: Color(0x2ED79A6C), // ~18% opacity
    gentle: Color(0xFF9BAE8A),
    gentleMuted: Color(0x2E9BAE8A),
    notice: Color(0xFFD1A85C),
    furBase: Color(0xFFDBB98C),
    furShadow: Color(0xFFB08D62),
    furHighlight: Color(0xFFEED9B7),
    furEarInner: Color(0xFFE7AE9C),
    furEyes: Color(0xFF4A3626),
    furNose: Color(0xFF8C5A4A),
    glassTint: Color(0x732A241D), // ~45% opacity
    glassBorder: Color(0x14FFFFFF), // ~8% white
    glassHighlight: Color(0x0FFFFFFF), // ~6% white
    glassShadow: Color(0x59000000), // ~35% black
    separator: Color(0x14FFFFFF), // ~8% white
  );

  @override
  VanyaColors copyWith() => this;

  @override
  VanyaColors lerp(ThemeExtension<VanyaColors>? other, double t) {
    if (other is! VanyaColors) return this;
    // Colors here are chosen as fixed pairs (light/dark), not interpolated
    // in practice — Flutter still requires `lerp` for the ThemeExtension
    // contract (e.g. implicit theme animations), so fall back to Color.lerp.
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VanyaColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceDeep: l(surfaceDeep, other.surfaceDeep),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textOnAccent: l(textOnAccent, other.textOnAccent),
      accent: l(accent, other.accent),
      accentMuted: l(accentMuted, other.accentMuted),
      gentle: l(gentle, other.gentle),
      gentleMuted: l(gentleMuted, other.gentleMuted),
      notice: l(notice, other.notice),
      furBase: l(furBase, other.furBase),
      furShadow: l(furShadow, other.furShadow),
      furHighlight: l(furHighlight, other.furHighlight),
      furEarInner: l(furEarInner, other.furEarInner),
      furEyes: l(furEyes, other.furEyes),
      furNose: l(furNose, other.furNose),
      glassTint: l(glassTint, other.glassTint),
      glassBorder: l(glassBorder, other.glassBorder),
      glassHighlight: l(glassHighlight, other.glassHighlight),
      glassShadow: l(glassShadow, other.glassShadow),
      separator: l(separator, other.separator),
    );
  }
}

/// `context.vanyaColors` — the Flutter equivalent of writing `VanyaColors.x`
/// directly in a SwiftUI view body. Falls back to [VanyaColors.light] only
/// if the extension was never registered on the theme (a programmer error,
/// not an expected runtime path).
extension VanyaColorsContext on BuildContext {
  VanyaColors get vanyaColors =>
      Theme.of(this).extension<VanyaColors>() ?? VanyaColors.light;
}
