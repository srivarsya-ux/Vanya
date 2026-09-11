import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_option_card.dart';
import '../widgets/onboarding_scaffold.dart';

class OnboardingMoment {
  const OnboardingMoment(this.icon, this.title);

  final IconData icon;
  final String title;
}

const List<OnboardingMoment> onboardingMoments = [
  OnboardingMoment(Icons.center_focus_strong_rounded, "When I'm meant to be focusing"),
  OnboardingMoment(Icons.hourglass_empty_rounded, "When I'm bored"),
  OnboardingMoment(Icons.bedtime_rounded, 'Before I sleep'),
  OnboardingMoment(Icons.spa_rounded, "When I'm stressed"),
  OnboardingMoment(Icons.hourglass_bottom_rounded, 'When I lose track of time'),
  OnboardingMoment(Icons.touch_app_rounded, 'When I keep checking without thinking'),
];

/// Screen 4 — Find Your Moment. The key psychological shift: Vanya isn't
/// going to control the whole day, she's going to show up when actually
/// needed — so multiple moments can be selected.
class OnboardingMomentsScreen extends StatelessWidget {
  const OnboardingMomentsScreen({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
    required this.onBack,
    required this.progressIndicator,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return OnboardingScaffold(
      onBack: onBack,
      progressIndicator: progressIndicator,
      bottomAction: VanyaGlassButton(
        label: 'Continue',
        onPressed: selected.isEmpty ? null : onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.md),
          const OnboardingIllustration(
            assetName: 'moments_meadow.jpg',
            aspectRatio: 16 / 8,
          ),
          const SizedBox(height: VanyaSpacing.xl),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When does Vanya\nneed to find you?',
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.sm),
                Text(
                  'Pick the moments when you find yourself reaching for '
                  'your phone.',
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VanyaSpacing.xl),
          for (final moment in onboardingMoments) ...[
            OnboardingOptionCard(
              icon: moment.icon,
              title: moment.title,
              selected: selected.contains(moment.title),
              onTap: () => onToggle(moment.title),
            ),
            const SizedBox(height: VanyaSpacing.sm),
          ],
          const SizedBox(height: VanyaSpacing.md),
        ],
      ),
    );
  }
}
