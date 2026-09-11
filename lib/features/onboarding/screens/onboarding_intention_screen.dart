import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_option_card.dart';
import '../widgets/onboarding_scaffold.dart';

class OnboardingIntention {
  const OnboardingIntention(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

const List<OnboardingIntention> onboardingIntentions = [
  OnboardingIntention(
    Icons.menu_book_rounded,
    'School',
    'Stay with the work in front of me',
  ),
  OnboardingIntention(
    Icons.palette_rounded,
    'Creating',
    'Make, draw, build, write',
  ),
  OnboardingIntention(
    Icons.people_alt_rounded,
    'People',
    'Be more present with the people around me',
  ),
  OnboardingIntention(
    Icons.nightlight_round,
    'Rest',
    'Wind down without getting pulled back in',
  ),
  OnboardingIntention(
    Icons.sports_tennis_rounded,
    'Hobbies',
    'Spend time doing things I actually enjoy',
  ),
  OnboardingIntention(
    Icons.auto_awesome_rounded,
    'Something else',
    'I have something different in mind',
  ),
];

/// Screen 3 — Set Your Intention. Vanya isn't about using your phone less;
/// it's about making room for something better, so this asks what for,
/// not how much.
class OnboardingIntentionScreen extends StatelessWidget {
  const OnboardingIntentionScreen({
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
            assetName: 'intention_meadow.jpg',
            aspectRatio: 16 / 8,
          ),
          const SizedBox(height: VanyaSpacing.xl),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like\na little more room for?',
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.sm),
                Text(
                  "Choose what you'd rather have more time and attention "
                  'for.',
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VanyaSpacing.xl),
          for (final intention in onboardingIntentions) ...[
            OnboardingOptionCard(
              icon: intention.icon,
              title: intention.title,
              subtitle: intention.subtitle,
              selected: selected.contains(intention.title),
              onTap: () => onToggle(intention.title),
            ),
            const SizedBox(height: VanyaSpacing.sm),
          ],
          const SizedBox(height: VanyaSpacing.md),
        ],
      ),
    );
  }
}
