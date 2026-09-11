import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../native/vanya_permissions.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_option_card.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen — Select Protected Apps. A real Android flow: queries the
/// device's actually-installed, launchable apps (see
/// `VanyaPermissions.listInstalledApps`) rather than showing a mockup list.
/// No apps selected is allowed — Vanya doesn't block on this, since apps
/// can be added anytime later.
class OnboardingProtectedAppsScreen extends StatefulWidget {
  const OnboardingProtectedAppsScreen({
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
  State<OnboardingProtectedAppsScreen> createState() =>
      _OnboardingProtectedAppsScreenState();
}

class _OnboardingProtectedAppsScreenState
    extends State<OnboardingProtectedAppsScreen> {
  List<InstalledApp>? _apps;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apps = await VanyaPermissions.listInstalledApps();
      if (!mounted) return;
      setState(() => _apps = apps);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final apps = _apps;

    return OnboardingScaffold(
      onBack: widget.onBack,
      progressIndicator: widget.progressIndicator,
      bottomAction: VanyaGlassButton(
        label: widget.selected.isEmpty ? 'Skip for now' : 'Continue',
        onPressed: widget.onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.md),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Which apps should\nVanya help with?',
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.sm),
                Text(
                  "Choose the apps where you'd like Vanya to gently step "
                  'in. You can add or remove apps anytime.',
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VanyaSpacing.xl),
          if (_error != null)
            VanyaGlassCard(
              child: Text(
                "Vanya couldn't load your apps just now "
                '($_error). You can try again later from Settings.',
                style: VanyaTypography.secondary.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else if (apps == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VanyaSpacing.xxl),
              child: Center(
                child: CircularProgressIndicator(color: colors.accent),
              ),
            )
          else
            for (final app in apps) ...[
              OnboardingOptionCard(
                icon: Icons.apps_rounded,
                title: app.label,
                selected: widget.selected.contains(app.packageName),
                onTap: () => widget.onToggle(app.packageName),
              ),
              const SizedBox(height: VanyaSpacing.sm),
            ],
          const SizedBox(height: VanyaSpacing.md),
        ],
      ),
    );
  }
}
