import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen 1 — The Arrival. Deliberately minimal: no stats, no permissions,
/// no "take control of your digital life." The first screen should create
/// curiosity, not sell the app.
class OnboardingArrivalScreen extends StatelessWidget {
  const OnboardingArrivalScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return OnboardingScaffold(
      bottomAction: VanyaGlassButton(
        label: 'Continue',
        onPressed: onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.xl),
          VanyaGlassCard(
            child: Text(
              'A little more\nroom for you.',
              style: VanyaTypography.display.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: VanyaSpacing.xxl),
          const OnboardingIllustration(assetName: 'arrival_meadow.jpg'),
          const SizedBox(height: VanyaSpacing.xl),
          VanyaGlassCard(
            child: Text(
              'Vanya helps you make space for the things you want to '
              'do — without asking you to disappear from your phone.',
              style: VanyaTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: VanyaSpacing.lg),
        ],
      ),
    );
  }
}
