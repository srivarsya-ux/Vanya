import 'package:flutter/material.dart';

import '../../../design_system/vanya_animation.dart';
import '../../../design_system/vanya_colors.dart';

/// A small, understated row of dots marking progress through onboarding —
/// deliberately not a labeled step counter or a progress bar with a
/// percentage. It should read as "you're moving through something," not as
/// a corporate setup wizard.
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          AnimatedContainer(
            duration: VanyaAnimation.gentleDuration,
            curve: VanyaAnimation.gentleCurve,
            width: i == currentStep ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i <= currentStep
                  ? colors.accent.withValues(alpha: 0.7)
                  : colors.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          if (i != totalSteps - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
