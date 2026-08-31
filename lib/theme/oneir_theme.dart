import 'package:flutter/material.dart';

/// Centralized design tokens for the whole app -- colour, type, spacing,
/// radius, and shadow. This is a full visual-design-system pass (see
/// SETUP.md/PR notes for the reference image this was built against): a
/// calm, warm, premium wellness-app aesthetic -- ivory/cream ground, deep
/// warm charcoal text, periwinkle used ONLY as a sparing accent, generous
/// whitespace, soft restrained shadows. This file is the single source of
/// truth; screens should never hardcode a raw Color/TextStyle/radius that
/// duplicates something already named here.
///
/// Nothing about the PRODUCT changed in this pass -- every screen, every
/// nav path, every piece of business logic is untouched. Only what these
/// tokens resolve to, and which widgets in shared.dart consume them.
class OneirColors {
  OneirColors._();

  // ---- Ground ----
  /// Warm ivory, not a cool/neutral off-white -- the base every screen sits
  /// on. Slightly warmer than pure paper white so it never reads as a bare
  /// Android background.
  static const Color background = Color(0xFFFAF7F2);

  /// Card/sheet surface -- a hair lighter than [background] so cards read
  /// as a distinct, gently raised layer without needing a heavy shadow to
  /// do that work.
  static const Color surface = Color(0xFFFFFDF9);

  /// A slightly deeper warm neutral for a card that should sit visually
  /// "one step back" from [surface] (e.g. a nested row inside a card).
  static const Color surfaceSunken = Color(0xFFF3EEE6);

  // ---- Text ----
  /// Deep warm charcoal -- never pure black. Primary reading colour.
  static const Color text = Color(0xFF2B2824);

  /// Muted warm grey -- secondary/supporting text.
  static const Color textMuted = Color(0xFF7A7268);

  /// Faintest text tier -- captions, timestamps, disabled labels.
  static const Color textFaint = Color(0xFFA79E90);

  /// Legacy alias kept for call sites -- see splash_screen.dart.
  static const Color splashWordmark = Color(0xFF5A5348);

  // ---- Accent (periwinkle) -- an accent, not a wash. Reserve for primary
  // actions, the selected state of a control, and small intentional
  // decorative marks. Never a whole card, background, or icon set. ----
  static const Color accent = Color(0xFF9691CC);
  static const Color accentStrong = Color(0xFF7D78B8);
  static const Color accentSoft = Color(0xFFEDEBF8); // wash, for a selected chip/row background
  static const Color accentLine = Color(0xFFD8D4EF); // a border that needs to read as "accent-tinted", not "grey"

  // ---- Structure ----
  /// Soft, low-contrast border -- warm-neutral, not the cold pure-grey
  /// Material default.
  static const Color border = Color(0xFFE7E0D4);
  static const Color borderStrong = Color(0xFFD8CFBF);

  static const Color inputFill = Color(0xFFF1ECE2);

  /// Legacy alias -- prefer [surfaceSunken] in new code.
  static const Color cardNeutral = Color(0xFFF3EEE6);

  // ---- Semantic (used sparingly, never as the accent) ----
  static const Color success = Color(0xFF6E8F6B);
  static const Color warning = Color(0xFFC08A4E);
}

/// One consistent type scale, used everywhere -- no screen picks its own
/// one-off font size. Every style already carries the right colour default
/// (override only when a specific row genuinely needs a different tone,
/// e.g. a disabled button label).
class OneirText {
  OneirText._();

  static const String _font = 'PlusJakartaSans';

  /// Large emphasis moments only (a splash wordmark, a celebration
  /// headline) -- not a default screen title.
  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    letterSpacing: -0.6,
    height: 1.15,
    color: OneirColors.text,
  );

  /// The standard screen headline ("What's your name?", "Good Morning,
  /// Alex").
  static const TextStyle heading = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.4,
    height: 1.2,
    color: OneirColors.text,
  );

  /// A card or section title -- smaller than a screen heading, still bold
  /// enough to anchor a group of content.
  static const TextStyle title = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: -0.1,
    height: 1.3,
    color: OneirColors.text,
  );

  /// Default reading text -- generous line height, medium (not bold)
  /// weight.
  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.55,
    color: OneirColors.textMuted,
  );

  /// A slightly heavier body row -- list-item labels, form values.
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.4,
    color: OneirColors.text,
  );

  /// Small secondary text -- helper copy under a heading, metadata.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.45,
    color: OneirColors.textMuted,
  );

  /// The smallest tier -- timestamps, eyebrow labels, faint captions.
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w500,
    fontSize: 11.5,
    letterSpacing: 0.2,
    height: 1.3,
    color: OneirColors.textFaint,
  );

  /// An uppercase eyebrow/section label (e.g. "TODAY", "FOCUS").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0.7,
    color: OneirColors.textFaint,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 15.5,
    letterSpacing: -0.1,
    color: Colors.white,
  );
}

/// A single 4px-based spacing scale -- every gap/padding in the app should
/// be one of these, not an arbitrary number, so vertical rhythm stays
/// consistent screen to screen.
class OneirSpace {
  OneirSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// The standard horizontal screen margin -- used by [OneirScreen] so no
  /// screen invents its own left/right padding.
  static const double screenMargin = 24;
}

/// Corner-radius tokens -- a card, a button, and a chip should each always
/// use the SAME radius across the whole app, not a slightly different
/// number per screen.
class OneirRadius {
  OneirRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Restrained, warm-tinted shadows -- never a hard black drop shadow. Used
/// via [OneirElevation.card] rather than any screen writing its own
/// BoxShadow list.
class OneirElevation {
  OneirElevation._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14261F0F), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// A lighter touch for a small inline element (a chip, a tag) that
  /// shouldn't read as "floating" as much as a full card.
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0D261F0F), blurRadius: 10, offset: Offset(0, 3)),
  ];
}

/// Design reference size every screen is authored against, then scaled to
/// the real device width in [OneirScaffold].
const double kDesignWidth = 351.7;
const double kDesignHeight = 715.3;
