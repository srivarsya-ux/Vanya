import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';

/// The shared skeleton every onboarding screen is built on: plain warm
/// background (illustration is the emotional layer here, not glass — see
/// the product brief's "glass is a hierarchy tool, not a default"), an
/// optional understated back button, a scrollable middle for content, and
/// a bottom-pinned call-to-action that respects the safe area.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.bottomAction,
    this.onBack,
    this.progressIndicator,
  });

  final Widget child;
  final Widget bottomAction;
  final VoidCallback? onBack;
  final Widget? progressIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.background),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ?progressIndicator,
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VanyaSpacing.lg,
                ),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VanyaSpacing.lg,
                VanyaSpacing.md,
                VanyaSpacing.lg,
                VanyaSpacing.lg,
              ),
              child: bottomAction,
            ),
          ],
        ),
      ),
    );
  }
}
