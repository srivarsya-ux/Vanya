import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/vanya_animation.dart';
import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';
import '../design_system/vanya_typography.dart';

class VanyaNavItem {
  const VanyaNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The bottom navigation shell — a floating glass bar rather than an
/// edge-to-edge opaque Material bottom nav, so the illustrated background
/// stays visible around and beneath it.
class VanyaGlassNavigation extends StatelessWidget {
  const VanyaGlassNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<VanyaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VanyaSpacing.lg,
        0,
        VanyaSpacing.lg,
        VanyaSpacing.md,
      ),
      child: VanyaGlass(
        borderRadius: VanyaRadius.xl,
        intensity: VanyaGlassIntensity.subtle,
        padding: const EdgeInsets.symmetric(
          horizontal: VanyaSpacing.sm,
          vertical: VanyaSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () {
                  if (i != selectedIndex) HapticFeedback.selectionClick();
                  onSelect(i);
                },
                colors: colors,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final VanyaNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final VanyaColors colors;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.accent : colors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: VanyaAnimation.quickDuration,
        curve: VanyaAnimation.quickCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: VanyaSpacing.md,
          vertical: VanyaSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accentMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(VanyaRadius.pill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: VanyaTypography.footnote.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
