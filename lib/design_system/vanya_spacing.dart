/// Vanya's spacing scale — a direct port of the SwiftUI `VanyaSpacing` enum.
/// Every layout gap, padding value, and stack spacing should come from here.
class VanyaSpacing {
  const VanyaSpacing._();

  /// 2 — hairline adjustments only.
  static const double xxs = 2;

  /// 4 — tight grouping (icon to label).
  static const double xs = 4;

  /// 8 — related elements within a component.
  static const double sm = 8;

  /// 12 — default spacing between rows inside a card.
  static const double md = 12;

  /// 16 — default screen margin and card padding.
  static const double lg = 16;

  /// 24 — spacing between distinct components.
  static const double xl = 24;

  /// 32 — spacing between sections.
  static const double xxl = 32;

  /// 48 — large separations (below a hero illustration).
  static const double xxxl = 48;

  /// 64 — screen-level breathing room (onboarding top margins).
  static const double huge = 64;
}
