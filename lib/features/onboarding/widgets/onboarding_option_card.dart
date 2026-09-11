import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/vanya_animation.dart';
import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_glass.dart';
import '../../../design_system/vanya_radius.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';

/// A large, tappable glass card for onboarding's choice screens (intention,
/// moments, promise duration) — heavier than [VanyaGlassChip], which is
/// meant for small inline pills, not a primary decision surface with its
/// own icon and supporting line.
///
/// Selection reads as a soft gradient wash fluttering in across the glass,
/// not a chip-style checkmark + border — the gradient is the only selected
/// affordance, so it needs to read clearly on its own.
class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: VanyaGlass(
        borderRadius: VanyaRadius.md,
        intensity: selected
            ? VanyaGlassIntensity.prominent
            : VanyaGlassIntensity.subtle,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                duration: VanyaAnimation.gentleDuration,
                curve: VanyaAnimation.gentleCurve,
                opacity: selected ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.accent.withValues(alpha: 0.32),
                        colors.accent.withValues(alpha: 0.10),
                        colors.accent.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VanyaSpacing.lg,
                vertical: VanyaSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? colors.accent : colors.textSecondary,
                  ),
                  const SizedBox(width: VanyaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: VanyaTypography.bodyEmphasized.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: VanyaSpacing.xxs),
                          Text(
                            subtitle!,
                            style: VanyaTypography.secondary.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
