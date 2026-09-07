import 'dart:ui';

import 'package:flutter/material.dart';

import 'vanya_colors.dart';
import 'vanya_radius.dart';

/// Vanya's glass material system — a deliberately hand-built equivalent of
/// the SwiftUI `VanyaMaterials.vanyaGlass()` modifier, not a generic
/// glassmorphism package. Every layer of the SwiftUI recipe has a matching
/// layer here:
///
/// 1. A real backdrop blur ([BackdropFilter]).
/// 2. A warm, semi-transparent tint over the blur.
/// 3. A gradient highlight stroke along the top edge only (not a full-area
///    wash) — the detail that makes the glass read as *lit* rather than
///    flat.
/// 4. A hairline border for edge definition.
/// 5. A soft drop shadow behind the whole shape.
///
/// Glass is a hierarchy tool, not a default: most of a screen should stay
/// plain background with illustration showing through, and only elements
/// that need to visually float (cards, sheets, nav bars, buttons) should be
/// wrapped in [VanyaGlass].
enum VanyaGlassIntensity {
  /// Nearly invisible — a hint of separation, for full-bleed surfaces like
  /// a navigation bar over an illustration.
  subtle(blurSigma: 8, tintMultiplier: 0.5),

  /// The default for cards and sheets.
  standard(blurSigma: 16, tintMultiplier: 0.75),

  /// Slightly denser — for controls that need to read clearly as
  /// interactive (primary buttons, toggles).
  prominent(blurSigma: 24, tintMultiplier: 0.9);

  const VanyaGlassIntensity({
    required this.blurSigma,
    required this.tintMultiplier,
  });

  final double blurSigma;
  final double tintMultiplier;
}

class VanyaGlass extends StatelessWidget {
  const VanyaGlass({
    super.key,
    required this.child,
    this.borderRadius = VanyaRadius.md,
    this.intensity = VanyaGlassIntensity.standard,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final VanyaGlassIntensity intensity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.glassShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: intensity.blurSigma,
            sigmaY: intensity.blurSigma,
          ),
          child: Stack(
            children: [
              // Layer 2: warm tint fill.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.glassTint.withValues(
                      alpha: colors.glassTint.a * intensity.tintMultiplier,
                    ),
                  ),
                ),
              ),
              // Layer 3: top-edge highlight stroke (gradient, edge-only —
              // not a full-area wash).
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TopHighlightBorderPainter(
                      radius: borderRadius,
                      highlight: colors.glassHighlight,
                    ),
                  ),
                ),
              ),
              // Layer 4: hairline border for edge definition.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: colors.glassBorder, width: 1),
                    ),
                  ),
                ),
              ),
              if (padding != null)
                Padding(padding: padding!, child: child)
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHighlightBorderPainter extends CustomPainter {
  _TopHighlightBorderPainter({required this.radius, required this.highlight});

  final double radius;
  final Color highlight;
  static const double _strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((radius - _strokeWidth / 2).clamp(0, radius)),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [highlight, highlight.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _TopHighlightBorderPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.highlight != highlight;
}
