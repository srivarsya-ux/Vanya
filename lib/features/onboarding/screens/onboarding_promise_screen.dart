import 'package:flutter/material.dart';

import '../../../design_system/vanya_animation.dart';
import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_glass.dart';
import '../../../design_system/vanya_radius.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_option_card.dart';
import '../widgets/onboarding_scaffold.dart';

class OnboardingPromiseOption {
  const OnboardingPromiseOption(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

const List<OnboardingPromiseOption> onboardingPromiseOptions = [
  OnboardingPromiseOption(
    Icons.spa_outlined,
    '15 minutes less',
    'A gentle beginning',
  ),
  OnboardingPromiseOption(
    Icons.wb_twilight_rounded,
    '30 minutes less',
    'A little more breathing room',
  ),
  OnboardingPromiseOption(
    Icons.landscape_rounded,
    '1 hour less',
    'A bigger change',
  ),
];

/// Screen 5 — Make Your First Promise. This is the only screen that asks
/// for commitment, and only after intention + moments have already been
/// established — so it reads as "let's make room for that", not "set your
/// screen time limit".
class OnboardingPromiseScreen extends StatelessWidget {
  const OnboardingPromiseScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.promiseMade,
    required this.onMakePromise,
    required this.onContinueAfterPromise,
    required this.onBack,
    required this.progressIndicator,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final bool promiseMade;
  final VoidCallback onMakePromise;
  final VoidCallback onContinueAfterPromise;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return OnboardingScaffold(
      onBack: promiseMade ? null : onBack,
      progressIndicator: progressIndicator,
      bottomAction: promiseMade
          ? VanyaGlassButton(
              label: 'Continue',
              onPressed: onContinueAfterPromise,
            )
          : VanyaGlassButton(
              label: 'Make my promise',
              style: VanyaGlassButtonStyle.accent,
              onPressed: selected == null ? null : onMakePromise,
            ),
      child: AnimatedSwitcher(
        duration: VanyaAnimation.gentleDuration,
        switchInCurve: VanyaAnimation.gentleCurve,
        child: promiseMade
            ? _PromiseMadeContent(colors: colors)
            : _PromiseChoiceContent(
                key: const ValueKey('choice'),
                colors: colors,
                selected: selected,
                onSelect: onSelect,
              ),
      ),
    );
  }
}

class _PromiseChoiceContent extends StatelessWidget {
  const _PromiseChoiceContent({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  final VanyaColors colors;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: VanyaSpacing.md),
        const OnboardingIllustration(
          assetName: 'promise_meadow.jpg',
          aspectRatio: 16 / 8,
        ),
        const SizedBox(height: VanyaSpacing.xl),
        VanyaGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's make a little\nroom for that.",
                style: VanyaTypography.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: VanyaSpacing.sm),
              Text(
                'Choose a goal that feels doable.',
                style: VanyaTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VanyaSpacing.xl),
        for (final option in onboardingPromiseOptions) ...[
          OnboardingOptionCard(
            icon: option.icon,
            title: option.title,
            subtitle: option.subtitle,
            selected: selected == option.title,
            onTap: () => onSelect(option.title),
          ),
          const SizedBox(height: VanyaSpacing.sm),
        ],
        const SizedBox(height: VanyaSpacing.md),
        VanyaGlassCard(
          borderRadius: VanyaRadius.sm,
          intensity: VanyaGlassIntensity.subtle,
          padding: const EdgeInsets.symmetric(
            horizontal: VanyaSpacing.md,
            vertical: VanyaSpacing.sm,
          ),
          child: Text(
            'You can change this anytime.',
            style: VanyaTypography.caption.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: VanyaSpacing.lg),
      ],
    );
  }
}

class _PromiseMadeContent extends StatelessWidget {
  const _PromiseMadeContent({required this.colors});

  final VanyaColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('made'),
      padding: const EdgeInsets.only(top: VanyaSpacing.huge),
      child: VanyaGlassCard(
        intensity: VanyaGlassIntensity.prominent,
        child: Column(
          children: [
            Icon(Icons.cruelty_free_rounded, size: 56, color: colors.accent),
            const SizedBox(height: VanyaSpacing.xl),
            Text(
              "Good. We'll start small.",
              textAlign: TextAlign.center,
              style: VanyaTypography.title.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
