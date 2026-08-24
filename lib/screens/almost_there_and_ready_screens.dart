import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

/// Step 11 -- "Almost There". A quick, reassuring summary that everything
/// from onboarding is in place, before the final "You're Ready" beat.
class AlmostThereScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const AlmostThereScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 17 / 18, onBack: onBack),
              const Spacer(flex: 2),
              // Steady and supportive -- everything's checked off, one
              // step to go, not a celebration yet (that's ReadyScreen).
              const VanyaCharacter(expression: VanyaExpression.encouraging, width: 235, height: 235),
              const SizedBox(height: 24),
              Text('Almost there.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, color: OneirColors.text)),
              const SizedBox(height: 12),
              const _ChecklistLine(label: 'Your name'),
              const _ChecklistLine(label: 'Protected apps'),
              const _ChecklistLine(label: 'Co-Keeper'),
              const _ChecklistLine(label: 'Permissions'),
              const Spacer(flex: 3),
              OneirPrimaryButton(label: 'Keep going', onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  final String label;
  const _ChecklistLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 18, color: OneirColors.text),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textMuted)),
        ],
      ),
    );
  }
}

/// Step 12 -- "You're Ready". The final onboarding beat before handing off
/// to the real Home screen.
class ReadyScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const ReadyScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 1.0, onBack: onBack),
              const Spacer(flex: 2),
              // A real win worth marking -- onboarding is actually
              // finished. This was showing the same wave-hello loop as
              // every other onboarding screen; now the one moment in the
              // whole flow that's genuinely a celebration looks like one.
              const VanyaCharacter(expression: VanyaExpression.proud, width: 255, height: 280),
              const SizedBox(height: 28),
              Text("You're all set.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 28, letterSpacing: -0.5, color: OneirColors.text)),
              const SizedBox(height: 12),
              Text("Let's make today count.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, height: 1.6, color: OneirColors.textMuted)),
              const Spacer(flex: 3),
              OneirPrimaryButton(label: 'Start My Journey', onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}
