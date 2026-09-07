import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/vanya_animation.dart';
import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';
import '../design_system/vanya_typography.dart';

/// A selectable glass pill — used for onboarding's multi-select choices
/// (intentions, reach-for-your-phone moments), day-of-week pickers, and
/// anywhere else a small set of options is chosen from.
class VanyaGlassChip extends StatelessWidget {
  const VanyaGlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: VanyaAnimation.quickDuration,
        curve: VanyaAnimation.quickCurve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VanyaRadius.pill),
          border: selected ? Border.all(color: colors.accent, width: 1.5) : null,
        ),
        child: VanyaGlass(
          borderRadius: VanyaRadius.pill,
          intensity: selected ? VanyaGlassIntensity.prominent : VanyaGlassIntensity.subtle,
          padding: const EdgeInsets.symmetric(
            horizontal: VanyaSpacing.lg,
            vertical: VanyaSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? colors.accent : colors.textSecondary,
                ),
                const SizedBox(width: VanyaSpacing.xs),
              ],
              Text(
                label,
                style: VanyaTypography.secondary.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
