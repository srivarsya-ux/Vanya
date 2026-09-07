/// Vanya's corner radius scale — a direct port of the SwiftUI `VanyaRadius`
/// enum. Glass surfaces use large but controlled radii: soft enough to feel
/// hand-made, restrained enough to stay premium.
class VanyaRadius {
  const VanyaRadius._();

  /// 12 — small controls (chips, inline buttons).
  static const double sm = 12;

  /// 20 — standard glass cards and sheets' inner content.
  static const double md = 20;

  /// 28 — hero cards, primary buttons.
  static const double lg = 28;

  /// 36 — full sheets and large presentation surfaces.
  static const double xl = 36;

  /// Fully rounded — pills, toggles, small circular controls.
  static const double pill = 999;
}
