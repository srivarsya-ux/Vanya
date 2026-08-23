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
      // speak(), not speakWithLipSync(): the lip-sync path synthesizes to a
      // WAV file, waits for it to finish writing to disk (polled every
      // 150ms, and can take several seconds on a real device), then relies
      // on a VanyaTalkingCharacter widget to actually play that file back --
      // this screen only shows a static VanyaAnimation, no such widget, so
      // the synthesized audio was never played at all. speak() uses live
      // TTS playback instead, which starts immediately and needs no
      // listening widget -- the right choice for any screen without a
      // VanyaTalkingCharacter on it (right now, only the intervention
      // conversation screen has one).
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
        // LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight)
        // instead of a plain fixed-height Column with Expanded/Spacer: on a
        // real device we saw the description text spill past the right edge
        // of the screen and the Continue button disappear entirely below
        // the fold. Whatever caused that (nothing in this file's own layout
        // math explains it -- verified by hand), this structure makes the
        // screen degrade to "scrollable" instead of "content silently cut
        // off" if it's ever taller than the available space, so the button
        // can never again be unreachable. crossAxisAlignment.stretch on the
        // Column + explicit maxLines/overflow on both Text widgets do the
        // same for the horizontal spill: every child now gets an
        // unambiguous, tight width instead of choosing its own.
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
                    OneirProgressHeader(progress: 1 / 18, onBack: widget.onBack),
                    const SizedBox(height: 8),
                    // Per the brief: Vanya centered, very subtle greenery,
                    // large empty space, clean background -- no crowded
                    // scene. Fixed height, not Expanded -- Expanded needs a
                    // bounded-height ancestor, which this scrollable
                    // Column deliberately no longer is.
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
