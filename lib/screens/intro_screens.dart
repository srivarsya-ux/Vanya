import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../intervention/voice/voice_queue_controller.dart';

/// Step 01 -- "Hello". Vanya appears, gives a small wave, and speaks for
/// real (per the brief: "Vanya's voice should play naturally") using the
/// same VoiceQueueController the intervention screen uses -- not a
/// separate onboarding-only voice system. This is why main.dart's root now
/// wraps in ProviderScope: Riverpod already existed in this codebase
/// (scoped to lib/intervention/), so reusing it here rather than building
/// a second voice pipeline just for onboarding.
class HelloScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const HelloScreen({super.key, required this.onNext, this.onBack});

  @override
  ConsumerState<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends ConsumerState<HelloScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(
            "Hello. I'm Vanya. I'll help you build a healthier relationship with your apps.",
            firstSentenceExtraPause: const Duration(milliseconds: 500),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 1 / 18, onBack: widget.onBack),
              const SizedBox(height: 8),
              // Per the brief: Vanya centered, very subtle greenery,
              // large empty space, clean background -- no crowded scene.
              Expanded(
                flex: 5,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: VanyaAnimation(width: 290, height: 343),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Hello. I\'m Vanya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.6, height: 1.15, color: OneirColors.text)),
              const SizedBox(height: 10),
              Text(
                "I'll help you build a healthier relationship with your apps.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.5, color: OneirColors.textMuted),
              ),
              const Spacer(),
              OneirPrimaryButton(label: 'Continue', onPressed: widget.onNext),
            ],
          ),
        ),
      ),
    );
  }
}
