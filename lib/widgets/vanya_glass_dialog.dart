import 'package:flutter/material.dart';

import '../design_system/vanya_colors.dart';
import '../design_system/vanya_glass.dart';
import '../design_system/vanya_radius.dart';
import '../design_system/vanya_spacing.dart';
import '../design_system/vanya_typography.dart';
import 'vanya_glass_button.dart';

class VanyaDialogAction {
  const VanyaDialogAction({
    required this.label,
    required this.onPressed,
    this.style = VanyaGlassButtonStyle.glass,
  });

  final String label;
  final VoidCallback onPressed;
  final VanyaGlassButtonStyle style;
}

/// A centered glass dialog for confirmations — e.g. "Reset onboarding?".
/// Deliberately plain: no destructive-red styling anywhere in Vanya, since
/// nothing in the product is framed as punishment, including its own
/// confirmation dialogs.
class VanyaGlassDialog extends StatelessWidget {
  const VanyaGlassDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<VanyaDialogAction> actions;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required List<VanyaDialogAction> actions,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (context) => VanyaGlassDialog(
        title: title,
        message: message,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: VanyaSpacing.xl),
      child: VanyaGlass(
        borderRadius: VanyaRadius.lg,
        intensity: VanyaGlassIntensity.standard,
        padding: const EdgeInsets.all(VanyaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: VanyaTypography.sectionTitle.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VanyaSpacing.sm),
            Text(
              message,
              style: VanyaTypography.secondary.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VanyaSpacing.xl),
            for (final action in actions) ...[
              SizedBox(
                width: double.infinity,
                child: Center(
                  child: VanyaGlassButton(
                    label: action.label,
                    style: action.style,
                    onPressed: () {
                      Navigator.of(context).pop();
                      action.onPressed();
                    },
                  ),
                ),
              ),
              if (action != actions.last) const SizedBox(height: VanyaSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
