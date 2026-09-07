import 'package:flutter/material.dart';

import 'vanya_colors.dart';
import 'vanya_typography.dart';

/// Builds the app's [ThemeData], with [VanyaColors] registered as a
/// [ThemeExtension] and the type scale wired into Material's [TextTheme] so
/// both custom Vanya widgets (`context.vanyaColors`, `VanyaTypography.x`)
/// and any incidental Material widget pick up the same palette and fonts.
class VanyaTheme {
  const VanyaTheme._();

  static ThemeData light() => _build(VanyaColors.light, Brightness.light);

  static ThemeData dark() => _build(VanyaColors.dark, Brightness.dark);

  static ThemeData _build(VanyaColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashFactory: NoSplash.splashFactory,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.textOnAccent,
        secondary: colors.gentle,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      textTheme: base.textTheme
          .copyWith(
            displayLarge: VanyaTypography.display,
            titleLarge: VanyaTypography.title,
            titleMedium: VanyaTypography.sectionTitle,
            bodyLarge: VanyaTypography.body,
            bodyMedium: VanyaTypography.secondary,
            labelLarge: VanyaTypography.control,
            bodySmall: VanyaTypography.caption,
            labelSmall: VanyaTypography.footnote,
          )
          .apply(
            bodyColor: colors.textPrimary,
            displayColor: colors.textPrimary,
          ),
      extensions: [colors],
    );
  }
}
