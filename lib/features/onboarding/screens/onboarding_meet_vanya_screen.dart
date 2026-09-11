import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen 2 — Meet Vanya. Establishes Vanya as a companion, not a
/// parental-control mascot: "No judgement. No lectures."
class OnboardingMeetVanyaScreen extends StatelessWidget {
  const OnboardingMeetVanyaScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return OnboardingScaffold(
      onBack: onBack,
      bottomAction: VanyaGlassButton(
        label: 'Continue',
        onPressed: onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.md),
          const OnboardingIllustration(
            assetName: 'meet_vanya_portrait.jpg',
            aspectRatio: 1,
          ),
          const SizedBox(height: VanyaSpacing.xxl),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is Vanya.',
                  style: VanyaTypography.display.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.md),
                Text(
                  "She'll be here when your phone starts asking for more "
                  'of your attention than you meant to give.',
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.lg),
                Text(
                  'No judgement. No lectures.',
                  style: VanyaTypography.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VanyaSpacing.lg),
        ],
      ),
    );
  }
}
