import 'package:flutter/material.dart';

import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';

/// The default glass surface for grouped content — the Flutter equivalent
/// of wrapping a SwiftUI view in `.vanyaGlass(cornerRadius: VanyaRadius.lg)`.
class VanyaGlassCard extends StatelessWidget {
  const VanyaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VanyaSpacing.lg),
    this.borderRadius = VanyaRadius.lg,
    this.intensity = VanyaGlassIntensity.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VanyaGlassIntensity intensity;

  @override
  Widget build(BuildContext context) {
    return VanyaGlass(
      borderRadius: borderRadius,
      intensity: intensity,
      padding: padding,
      child: child,
    );
  }
}
