import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

class _PermissionRow {
  final String label;
  final String reason;
  const _PermissionRow(this.label, this.reason);
}

const _permissions = [
  _PermissionRow('Notifications', "So I can celebrate wins and remind you kindly."),
  _PermissionRow('Display Over Apps', "So I can gently remind you before you scroll."),
  _PermissionRow('Accessibility', "So protected apps actually stay protected."),
];

/// Step 10 -- "Enable Protection". An overview of what's about to be asked
/// for and why, before the three individual permission screens (each with
/// its own real OS request) run in sequence. Framed as one step in the
/// story rather than a wall of technical toggles.
///
/// NOTE: this content is scrollable rather than fixed -- with three cards
/// plus the illustration and heading, the total content was taller than the
/// screen on some sizes, which pushed the Continue button below the visible
/// area entirely (it existed in the widget tree but was neither visible nor
/// tappable). A ScrollView here means the button can never be pushed off
/// like that, regardless of content length or screen size.
class EnableProtectionScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const EnableProtectionScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OneirProgressHeader(progress: 9 / 18, onBack: onBack),
          const SizedBox(height: OneirSpace.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: VanyaCharacter(expression: VanyaExpression.protecting, width: 180, height: 168),
                  ),
                  const SizedBox(height: OneirSpace.lg),
                  const Text('A few permissions', style: OneirText.heading),
                  const SizedBox(height: OneirSpace.sm),
                  Text("Here's what I'll ask for next, and why -- you'll approve each one yourself.",
                      style: OneirText.body.copyWith(fontSize: 14, height: 1.5)),
                  const SizedBox(height: OneirSpace.xxl),
                  for (final p in _permissions) ...[
                    OneirCard(
                      padding: const EdgeInsets.all(OneirSpace.lg),
                      elevated: false,
                      bordered: false,
                      color: OneirColors.surfaceSunken,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label, style: OneirText.title.copyWith(fontSize: 15)),
                          const SizedBox(height: OneirSpace.xs),
                          Text(p.reason, style: OneirText.bodySmall.copyWith(height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: OneirSpace.md - 2),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: OneirSpace.lg),
          OneirPrimaryButton(label: "Got it, let's go", onPressed: onNext),
        ],
      ),
    );
  }
}
