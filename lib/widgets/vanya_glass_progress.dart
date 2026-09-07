import 'package:flutter/material.dart';

import '../design_system/vanya_animation.dart';
import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';

/// A linear progress indicator in a glass track — used for Focus session
/// progress and anywhere else a quiet, non-alarming progress readout is
/// needed. Never paired with a numeric percentage callout; the fill itself
/// is the whole story.
class VanyaGlassProgress extends StatelessWidget {
  const VanyaGlassProgress({
    super.key,
    required this.value,
    this.height = 10,
  });

  /// 0.0–1.0. Values outside that range are clamped.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final clamped = value.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: VanyaGlass(
        borderRadius: VanyaRadius.pill,
        intensity: VanyaGlassIntensity.subtle,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: VanyaAnimation.gentleDuration,
                curve: VanyaAnimation.gentleCurve,
                width: constraints.maxWidth * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(VanyaRadius.pill),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
