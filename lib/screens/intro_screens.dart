import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../intervention/voice/voice_queue_controller.dart';

/// Step 01 -- "Hello". Vanya appears, gives a small wave, and speaks for
/// real using the same VoiceQueueController the intervention screen uses.
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
      // speak(), not speakWithLipSync(): the lip-sync path synthesizes to a
      // WAV file, waits for it to finish writing to disk, then relies on a
      // VanyaTalkingCharacter widget to play that file back -- this screen
      // only shows a static VanyaAnimation, no such widget, so the
      // synthesized audio was never played at all. speak() uses live TTS
      // playback instead, starting immediately.
      ref.read(voiceQueueControllerProvider.notifier).speak(
            "Hello. I'm Vanya. I'll help you build a healthier relationship with your apps.",
            firstSentenceExtraPause: const Duration(milliseconds: 500),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, outer) {
            const padding = EdgeInsets.fromLTRB(26, 20, 26, 24);
            final minContentHeight = outer.maxHeight - padding.vertical;
            return SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight > 0 ? minContentHeight : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TEMPORARY build-verification marker (v4). Remove once
                    // the canvas fix is confirmed on-device.
                    Container(
                      color: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Text(
                        'BUILD CHECK v4',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OneirProgressHeader(progress: 1 / 18, onBack: widget.onBack),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: (minContentHeight > 0 ? minContentHeight : 400) * 0.34,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 32, letterSpacing: -0.6, height: 1.15, color: OneirColors.text)),
                    const SizedBox(height: 10),
                    Text(
                      "I'll help you build a healthier relationship with your apps.",
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.5, color: OneirColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    OneirPrimaryButton(label: 'Continue', onPressed: widget.onNext),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
