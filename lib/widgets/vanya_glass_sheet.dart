import 'package:flutter/material.dart';

import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';

/// A bottom sheet surface built from glass, with a drag handle and
/// top-only rounded corners. Use [VanyaGlassSheet.show] rather than
/// constructing this directly, so the surrounding [showModalBottomSheet]
/// chrome (barrier color, transparent scaffold background) is set up
/// consistently everywhere.
class VanyaGlassSheet extends StatelessWidget {
  const VanyaGlassSheet({super.key, required this.child});

  final Widget child;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VanyaGlassSheet(child: builder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VanyaRadius.xl),
        ),
        child: VanyaGlass(
          borderRadius: VanyaRadius.xl,
          intensity: VanyaGlassIntensity.standard,
          padding: const EdgeInsets.fromLTRB(
            VanyaSpacing.lg,
            VanyaSpacing.sm,
            VanyaSpacing.lg,
            VanyaSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: VanyaSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(VanyaRadius.pill),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
