import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import 'co_keeper_screens.dart' show FlowDiagram;

/// Step 02 -- explains why repeated app-opening becomes automatic, using
/// the Trigger -> Open App -> Quick Reward -> Repeat -> Automatic Habit
/// loop. Deliberately short and conversational, not a lecture -- one
/// visual, one Vanya line, nothing else on the screen.
class HowAppHabitsWorkScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const HowAppHabitsWorkScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 3 / 18, onBack: onBack),
              const Spacer(flex: 2),
              const VanyaAnimation(width: 195, height: 195),
              const SizedBox(height: 22),
              FlowDiagram(steps: const ['Trigger', 'Open App', 'Quick Reward', 'Repeat', 'Automatic Habit']),
              const SizedBox(height: 22),
              Text(
                "Sometimes you don't even decide to open an app anymore. Your brain starts doing it almost automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, height: 1.5, color: OneirColors.text),
              ),
              const Spacer(flex: 3),
              OneirPrimaryButton(label: 'Continue', onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }
}
