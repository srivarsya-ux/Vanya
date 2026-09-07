import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/vanya_animation.dart';
import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';

/// A glass-styled switch: a translucent pill track with a solid thumb that
/// slides between the two states. Replaces Material's [Switch] wherever the
/// control should feel like part of Vanya's world rather than stock Android.
class VanyaGlassToggle extends StatelessWidget {
  const VanyaGlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 52;
  static const double _height = 30;
  static const double _thumbSize = 24;
  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final disabled = onChanged == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        child: SizedBox(
          width: _width,
          height: _height,
          child: VanyaGlass(
            borderRadius: VanyaRadius.pill,
            intensity: VanyaGlassIntensity.prominent,
            child: AnimatedContainer(
              width: _width,
              height: _height,
              duration: VanyaAnimation.quickDuration,
              curve: VanyaAnimation.quickCurve,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: _inset),
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? colors.accent : colors.textTertiary,
                  boxShadow: [
                    BoxShadow(
                      color: colors.glassShadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
