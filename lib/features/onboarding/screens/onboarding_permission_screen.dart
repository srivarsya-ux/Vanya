import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_scaffold.dart';

/// One reusable screen for every permission Vanya asks for — Usage Access,
/// drawing over other apps, Notifications, Battery-optimization exemption,
/// Accessibility. Each is granted in system Settings (or, for Notifications,
/// a runtime dialog) and the user returns to the app afterward, so this
/// screen re-checks the *real* state via [checkGranted] on every resume —
/// it never assumes tapping the button meant success. Continue always stays
/// enabled: Vanya explains and asks, it doesn't trap the user into granting
/// something they've decided not to (item 13 — never fake success, but also
/// never force).
class OnboardingPermissionScreen extends StatefulWidget {
  const OnboardingPermissionScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
    required this.actionLabel,
    required this.checkGranted,
    required this.requestAction,
    required this.onGrantedChanged,
    required this.onContinue,
    required this.onBack,
    required this.progressIndicator,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final String actionLabel;
  final Future<bool> Function() checkGranted;
  final Future<void> Function() requestAction;
  final ValueChanged<bool> onGrantedChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  State<OnboardingPermissionScreen> createState() =>
      _OnboardingPermissionScreenState();
}

class _OnboardingPermissionScreenState
    extends State<OnboardingPermissionScreen> with WidgetsBindingObserver {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final granted = await widget.checkGranted();
    if (!mounted) return;
    setState(() => _granted = granted);
    widget.onGrantedChanged(granted);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final granted = _granted ?? false;

    return OnboardingScaffold(
      onBack: widget.onBack,
      progressIndicator: widget.progressIndicator,
      bottomAction: VanyaGlassButton(
        label: 'Continue',
        onPressed: widget.onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.huge),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, size: 32, color: colors.accent),
                const SizedBox(height: VanyaSpacing.lg),
                Text(
                  widget.title,
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.md),
                Text(
                  widget.explanation,
                  style: VanyaTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VanyaSpacing.xl),
          VanyaGlassButton(
            label: granted ? '${widget.actionLabel} — On' : widget.actionLabel,
            icon: granted ? Icons.check_circle_rounded : null,
            style: granted
                ? VanyaGlassButtonStyle.glass
                : VanyaGlassButtonStyle.accent,
            onPressed: granted ? null : () => widget.requestAction(),
          ),
        ],
      ),
    );
  }
}
