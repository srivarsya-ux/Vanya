import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_radius.dart';

/// The rounded illustration card used at the top of the early onboarding
/// screens. Tries to load the real Vanya artwork from
/// `assets/images/onboarding/<assetName>` first; if that file doesn't exist
/// yet, falls back to a soft gradient placeholder evoking the meadow/sunset
/// reference art (dusk blue -> gold) with a simple rabbit silhouette — so
/// dropping the real PNG into that folder later requires no code change.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.assetName,
    this.aspectRatio = 16 / 11,
  });

  final String assetName;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VanyaRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colors.glassShadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VanyaRadius.lg),
          child: Image.asset(
            'assets/images/onboarding/$assetName',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _placeholder(colors),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(VanyaColors colors) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5C7A9E), // dusk blue
            Color(0xFFE8C888), // gold
            Color(0xFFDCEAC2), // meadow green, faded
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.cruelty_free_rounded,
          size: 64,
          color: colors.background.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
