import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/vanya_animation.dart';
import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';
import '../design_system/vanya_typography.dart';

/// A button's visual weight. `glass` is the translucent secondary style;
/// `accent` is a solid-fill primary style (still capsule-shaped, still
/// using the same press interaction) for the one or two calls to action
/// per screen that should read as the obvious next step.
enum VanyaGlassButtonStyle { glass, accent }

/// Vanya's button — a gentle scale-down on press (no bounce, no ripple;
/// `NoSplash` is set globally in `VanyaTheme`), built on [VanyaGlass] for
/// the `.glass` style.
class VanyaGlassButton extends StatefulWidget {
  const VanyaGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = VanyaGlassButtonStyle.glass,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final VanyaGlassButtonStyle style;
  final IconData? icon;

  @override
  State<VanyaGlassButton> createState() => _VanyaGlassButtonState();
}

class _VanyaGlassButtonState extends State<VanyaGlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final disabled = widget.onPressed == null;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: widget.style == VanyaGlassButtonStyle.accent
                ? colors.textOnAccent
                : colors.textPrimary,
          ),
          const SizedBox(width: VanyaSpacing.sm),
        ],
        Text(
          widget.label,
          style: VanyaTypography.control.copyWith(
            color: widget.style == VanyaGlassButtonStyle.accent
                ? colors.textOnAccent
                : colors.textPrimary,
          ),
        ),
      ],
    );

    final inner = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VanyaSpacing.xl,
        vertical: VanyaSpacing.md,
      ),
      child: content,
    );

    final child = widget.style == VanyaGlassButtonStyle.accent
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(VanyaRadius.pill),
            ),
            child: inner,
          )
        : VanyaGlass(
            borderRadius: VanyaRadius.pill,
            intensity: VanyaGlassIntensity.prominent,
            child: inner,
          );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: VanyaAnimation.quickDuration,
          curve: VanyaAnimation.quickCurve,
          child: child,
        ),
      ),
    );
  }
}
