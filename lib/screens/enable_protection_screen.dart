import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
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
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 9 / 18, onBack: onBack),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: VanyaAnimation(width: 180, height: 168),
                      ),
                      const SizedBox(height: 16),
                      const Text('A few permissions',
                          style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, height: 1.25, color: OneirColors.text)),
                      const SizedBox(height: 8),
                      const Text("Here's what I'll ask for next, and why -- you'll approve each one yourself.",
                          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.5, color: OneirColors.textFaint)),
                      const SizedBox(height: 24),
                      for (final p in _permissions) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
                              const SizedBox(height: 4),
                              Text(p.reason, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, height: 1.4, color: OneirColors.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OneirPrimaryButton(label: "Got it, let's go", onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}
