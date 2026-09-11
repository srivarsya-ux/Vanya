import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen — end of this phase of onboarding. Honest about where things
/// stand: Vanya is set up to notice and gently step in for the apps and
/// permissions just configured. Choosing a Co-Keeper, setting up widgets,
/// and building a task list are real, separate pieces of work that come
/// next — this screen says so instead of pretending "all done."
class OnboardingReadyScreen extends StatelessWidget {
  const OnboardingReadyScreen({
    super.key,
    required this.userName,
    required this.onBack,
    required this.progressIndicator,
  });

  final String? userName;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final name = (userName == null || userName!.isEmpty) ? '' : ', $userName';

    return OnboardingScaffold(
      onBack: onBack,
      progressIndicator: progressIndicator,
      bottomAction: const SizedBox(height: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.huge),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.cruelty_free_rounded,
                  size: 48,
                  color: colors.accent,
                ),
                const SizedBox(height: VanyaSpacing.lg),
                Text(
                  "You're set up$name.",
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.md),
                Text(
                  "Vanya can now notice the moments you set up and the "
                  "apps you chose. Choosing a Co-Keeper, setting up your "
                  "widgets, and building your task list are next — for "
                  "now, this is where today's setup ends.",
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
