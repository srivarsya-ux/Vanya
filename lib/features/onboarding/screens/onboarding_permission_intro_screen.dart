import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen — Explain How Vanya Works. Sets context before any individual
/// permission request, per the spec: never dump every permission on one
/// giant settings page without saying why first.
class OnboardingPermissionIntroScreen extends StatelessWidget {
  const OnboardingPermissionIntroScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.progressIndicator,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return OnboardingScaffold(
      onBack: onBack,
      progressIndicator: progressIndicator,
      bottomAction: VanyaGlassButton(label: 'Continue', onPressed: onContinue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.huge),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A few things Vanya\nneeds to notice.',
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.md),
                Text(
                  "For Vanya to gently step in when you open a protected "
                  "app, your phone needs to let her notice it — that's a "
                  "few Android permissions, not a blank check. On the "
                  "next few screens I'll explain each one before asking, "
                  "and you'll always be able to see exactly what's on.",
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
