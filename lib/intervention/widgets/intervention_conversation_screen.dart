import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/oneir_theme.dart';
import '../../widgets/shared.dart';
import '../providers/intervention_controller.dart';
import '../providers/intervention_state.dart';
import '../models/intervention_decision.dart';
import '../ai/ai_intervention_provider.dart';
import '../voice/voice_queue_controller.dart';
import '../voice/speech_input_controller.dart';
import '../lipsync/vanya_talking_character.dart';
import '../quickreason/quick_reason.dart';
import '../quickreason/quick_reason_responses.dart';
import '../quickreason/quick_reason_action_handler.dart';
import '../quickreason/intervention_context.dart';

/// The full-screen Vanya overlay shown when a protected app opens. Reuses
/// the existing design system (OneirColors/OneirText/shared buttons) --
/// this is new *behavior*, not a new visual language.
class InterventionConversationScreen extends ConsumerStatefulWidget {
  final String appLabel;
  final String packageName;
  final bool isReLockFollowUp;
  final VoidCallback onDismiss;
  final VoidCallback onLaunchApp;

  const InterventionConversationScreen({
    super.key,
    required this.appLabel,
    required this.packageName,
    required this.onDismiss,
    required this.onLaunchApp,
    this.isReLockFollowUp = false,
  });

  @override
  ConsumerState<InterventionConversationScreen> createState() => _InterventionConversationScreenState();
}

class _InterventionConversationScreenState extends ConsumerState<InterventionConversationScreen> {
  final _controller = TextEditingController();
  bool _hasInterruptedForThisTurn = false;
  QuickReasonResponse? _quickResponse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interventionControllerProvider.notifier).start(
            appLabel: widget.appLabel,
            packageName: widget.packageName,
            isReLockFollowUp: widget.isReLockFollowUp,
          );
      if (!widget.isReLockFollowUp) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) ref.read(interventionControllerProvider.notifier).readyForInput();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Belt-and-braces: if this screen is torn down for any reason (e.g.
    // the native side dismisses the Activity abruptly), Vanya shouldn't
    // keep talking into a closed overlay, and the mic shouldn't be left
    // listening either.
    ref.read(voiceQueueControllerProvider.notifier).interrupt();
    ref.read(speechInputControllerProvider.notifier).stopListening();
    super.dispose();
  }

  void _submit([String? overrideText]) {
    final text = overrideText ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(speechInputControllerProvider.notifier).clearTranscript();
    _hasInterruptedForThisTurn = false;
    ref.read(interventionControllerProvider.notifier).submitUserMessage(text);
  }

  /// The moment the user starts typing an answer, Vanya shouldn't keep
  /// talking over them -- interrupt on the first keystroke of each turn
  /// rather than on every keystroke.
  void _onTextChanged(String value) {
    if (!_hasInterruptedForThisTurn && value.isNotEmpty) {
      _hasInterruptedForThisTurn = true;
      ref.read(voiceQueueControllerProvider.notifier).interrupt();
    }
  }

  Future<void> _toggleMic() async {
    final speech = ref.read(speechInputControllerProvider);
    final speechController = ref.read(speechInputControllerProvider.notifier);
    if (speech.isListening) {
      await speechController.stopListening();
      // Auto-submit whatever was transcribed when the user stops the mic
      // themselves -- matches "reply by voice" feeling like an actual
      // reply, not just filling in the text box for them to also press Send.
      final transcript = ref.read(speechInputControllerProvider).transcript;
      if (transcript.trim().isNotEmpty) _submit(transcript);
    } else {
      if (!_hasInterruptedForThisTurn) {
        _hasInterruptedForThisTurn = true;
        await ref.read(voiceQueueControllerProvider.notifier).interrupt();
      }
      await speechController.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interventionControllerProvider);
    final voiceState = ref.watch(voiceQueueControllerProvider);

    // Live-dictation fix: the transcript used to only ever appear as a
    // small italic preview line below the input box while the real
    // TextField stayed empty the whole time -- easy to mistake for
    // dictation just not working. This mirrors it straight into the real
    // text field as it comes in, cursor kept at the end, same as
    // dictation behaves anywhere else on the phone.
    ref.listen(speechInputControllerProvider, (previous, next) {
      if (!next.isListening) return;
      if (next.transcript == previous?.transcript) return;
      _controller.text = next.transcript;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });

    ref.listen(interventionControllerProvider, (previous, next) {
      if (next?.stage == InterventionStage.closed) {
        if (next?.lastDecision?.decision == InterventionDecisionType.allow) {
          widget.onLaunchApp();
        } else {
          widget.onDismiss();
        }
      }
      if (previous?.stage != next?.stage) {
        _hasInterruptedForThisTurn = false;
      }
    });

    if (state == null) {
      return const Scaffold(
        backgroundColor: OneirColors.background,
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(OneirColors.accent))),
      );
    }

    // A warm, calm scrim rather than a harsh pure-black overlay, and an
    // ivory card with the app's standard soft shadow/border -- this should
    // read as a caring check-in, not a system alert or blocker.
    return Scaffold(
      backgroundColor: OneirColors.text.withOpacity(0.45),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 340,
            constraints: const BoxConstraints(maxHeight: 660),
            padding: const EdgeInsets.fromLTRB(OneirSpace.xxl, OneirSpace.lg, OneirSpace.xxl, OneirSpace.xl),
            decoration: BoxDecoration(
              color: OneirColors.surface,
              borderRadius: BorderRadius.circular(OneirRadius.xl),
              border: Border.all(color: OneirColors.border),
              boxShadow: OneirElevation.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VoiceControlsRow(),
                // The real, audio-driven talking character -- mouth is
                // synchronized to actual analyzed TTS audio (see
                // lib/intervention/lipsync/), not estimated from text.
                // Works for any dialogue Vanya is given; nothing here is
                // specific to what she's currently saying.
                VanyaTalkingCharacter(
                  audio: voiceState.currentAudioPath,
                  lipSyncData: voiceState.currentLipSyncTimeline,
                  isSpeaking: voiceState.isSpeaking,
                  // 108, not the old 162 -- the bunny body art is a tall
                  // portrait (997x1720), not the square face-crop the old
                  // photo-based version used, so the same width now comes
                  // out much taller. 108 keeps the full card comfortably
                  // inside its 660 maxHeight alongside the conversation
                  // content below, without a UI redesign of this screen.
                  size: 108,
                  lineColor: OneirColors.text,
                  accentColor: OneirColors.text,
                ),
                const SizedBox(height: OneirSpace.md),
                Flexible(child: _buildStageContent(state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(InterventionState state) {
    switch (state.stage) {
      case InterventionStage.detecting:
        return const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(OneirColors.accent))),
        );

      case InterventionStage.speaking:
        return _headline('Hi. What are you hoping to do?');

      case InterventionStage.awaitingInput:
      case InterventionStage.clarifying:
        return _conversationWithInput(state);

      case InterventionStage.thinking:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _conversationHistory(state),
          const SizedBox(height: OneirSpace.lg),
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(OneirColors.accent)),
          ),
        ]);

      case InterventionStage.decided:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _headline(state.lastDecision?.reply ?? ''),
          const SizedBox(height: OneirSpace.xl),
          OneirPrimaryButton(label: 'Okay', onPressed: () => ref.read(interventionControllerProvider.notifier).close()),
        ]);

      case InterventionStage.sessionActive:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text("You're set for ${widget.appLabel}.", textAlign: TextAlign.center, style: OneirText.title),
          const SizedBox(height: OneirSpace.sm),
          Text("I'll check back in when your time is up.",
              textAlign: TextAlign.center, style: OneirText.bodySmall.copyWith(color: OneirColors.textFaint)),
        ]);

      case InterventionStage.reLockPrompt:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _headline('Have you finished?'),
          const SizedBox(height: OneirSpace.xl),
          OneirPrimaryButton(label: "Yes, I'm done", onPressed: () => ref.read(interventionControllerProvider.notifier).confirmSessionFinished()),
          const SizedBox(height: OneirSpace.md),
          OneirSecondaryButton(
            label: 'Not quite, one more moment',
            onPressed: () => _showMoreTimeSheet(state),
          ),
        ]);

      case InterventionStage.closed:
        return const SizedBox.shrink();
    }
  }

  void _handleQuickReason(QuickReason reason) {
    final context = InterventionContext(appLabel: widget.appLabel, packageName: widget.packageName);
    final response = QuickReasonResponses.resolve(reason, context);
    setState(() => _quickResponse = response);
    ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(response.dialogue);
  }

  Future<void> _handleQuickAction(InterventionAction action) async {
    await QuickReasonActionHandler.execute(action, packageName: widget.packageName, appLabel: widget.appLabel);
    if (action == InterventionAction.continueToApp) {
      widget.onLaunchApp();
    } else {
      widget.onDismiss();
    }
  }

  String _actionLabel(InterventionAction action) {
    switch (action) {
      case InterventionAction.backToTask:
        return 'Back to task';
      case InterventionAction.startShortBreak:
        return 'Start 5 min break';
      case InterventionAction.askCoKeeper:
        return 'Ask Co-Keeper';
      case InterventionAction.continueToApp:
        return 'Continue';
      case InterventionAction.returnToPrevious:
        return 'Okay';
    }
  }

  Widget _quickResponseView(QuickReasonResponse response) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _headline(response.dialogue),
      const SizedBox(height: OneirSpace.xl),
      for (var i = 0; i < response.actions.length; i++) ...[
        if (i == 0)
          OneirPrimaryButton(label: _actionLabel(response.actions[i]), onPressed: () => _handleQuickAction(response.actions[i]))
        else
          OneirSecondaryButton(label: _actionLabel(response.actions[i]), onPressed: () => _handleQuickAction(response.actions[i])),
        if (i < response.actions.length - 1) const SizedBox(height: OneirSpace.md),
      ],
    ]);
  }

  Widget _headline(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: OneirText.title.copyWith(height: 1.4),
    );
  }

  Widget _conversationHistory(InterventionState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final turn in state.history) _ChatBubble(turn: turn),
      ],
    );
  }

  Widget _conversationWithInput(InterventionState state) {
    final question = state.stage == InterventionStage.clarifying
        ? (state.lastDecision?.clarifyingQuestion ?? state.lastDecision?.reply ?? "What's going on?")
        : "What's bringing you to ${widget.appLabel}?";

    final speech = ref.watch(speechInputControllerProvider);

    if (_quickResponse != null) {
      return _quickResponseView(_quickResponse!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.history.isNotEmpty) ...[
          _conversationHistory(state),
          const SizedBox(height: OneirSpace.sm),
        ],
        _headline(question),
        const SizedBox(height: OneirSpace.lg),
        // Quick-select reasons -- a fast local branch that sits alongside
        // the free-text AI conversation below, not a replacement for it.
        // Only shown on the initial ask, not on the AI's own follow-up
        // clarifying questions (a different context).
        if (state.stage == InterventionStage.awaitingInput) ...[
          _QuickReasonChips(onSelected: _handleQuickReason),
          const SizedBox(height: OneirSpace.lg),
          Row(children: [
            const Expanded(child: Divider(color: OneirColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OneirSpace.sm + 2),
              child: Text('or tell me more', style: OneirText.caption),
            ),
            const Expanded(child: Divider(color: OneirColors.border)),
          ]),
          const SizedBox(height: OneirSpace.lg),
        ],
        // Restyled with OneirTextField's warm-fill visual language; the mic
        // button rides in the field's suffix slot rather than sitting in a
        // separate Row, but the controller/onChanged/onSubmitted wiring
        // that drives dictation and interruption is unchanged.
        OneirTextField(
          controller: _controller,
          autofocus: true,
          maxLines: 2,
          onChanged: _onTextChanged,
          onSubmitted: (_) => _submit(),
          hintText: speech.isListening ? 'Listening...' : 'Type or tap the mic to speak...',
          suffix: Padding(
            padding: const EdgeInsets.all(OneirSpace.xs),
            child: Material(
              color: speech.isListening ? OneirColors.accent : OneirColors.surfaceSunken,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggleMic,
                child: Padding(
                  padding: const EdgeInsets.all(OneirSpace.sm),
                  child: Icon(
                    speech.isListening ? Icons.mic : Icons.mic_none,
                    size: 20,
                    color: speech.isListening ? Colors.white : OneirColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: OneirSpace.md),
        OneirPrimaryButton(label: 'Send', onPressed: () => _submit()),
      ],
    );
  }

  void _showMoreTimeSheet(InterventionState state) {
    final extraController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: OneirColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            OneirSpace.xxl, OneirSpace.xxl, OneirSpace.xxl, MediaQuery.of(context).viewInsets.bottom + OneirSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What do you still need to finish?', style: OneirText.title),
            const SizedBox(height: OneirSpace.md),
            OneirTextField(controller: extraController, autofocus: true),
            const SizedBox(height: OneirSpace.lg),
            OneirPrimaryButton(
              label: 'Send',
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(interventionControllerProvider.notifier).requestMoreTime(extraController.text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Small header row: replay the last thing Vanya said, and adjust how
/// fast she speaks. Kept tiny and unobtrusive -- this is a utility control,
/// not a feature to draw attention to.
class _VoiceControlsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceQueueControllerProvider);
    final voiceController = ref.read(voiceQueueControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: voiceController.hasSomethingToReplay ? voiceController.replay : null,
          icon: Icon(Icons.replay, size: 18, color: voiceController.hasSomethingToReplay ? OneirColors.textMuted : OneirColors.textFaint),
          tooltip: 'Replay',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: () => _showSpeedSheet(context, ref, voiceState.rate),
          icon: const Icon(Icons.speed, size: 18, color: OneirColors.textMuted),
          tooltip: 'Speaking speed',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showSpeedSheet(BuildContext context, WidgetRef ref, double currentRate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OneirColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          var localRate = currentRate;
          return Padding(
            padding: const EdgeInsets.fromLTRB(OneirSpace.xxl, OneirSpace.xxl, OneirSpace.xxl, OneirSpace.xxxl - 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Speaking speed', style: OneirText.title),
                Slider(
                  value: localRate,
                  min: 0.2,
                  max: 0.9,
                  activeColor: OneirColors.accent,
                  onChanged: (v) => setSheetState(() => localRate = v),
                  onChangeEnd: (v) => ref.read(voiceQueueControllerProvider.notifier).setRate(v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickReasonChips extends StatelessWidget {
  final ValueChanged<QuickReason> onSelected;
  const _QuickReasonChips({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Generic over QuickReason.values -- adding a 5th reason later needs
    // no change here, only a new enum value + a new rule in
    // QuickReasonResponses.
    return Wrap(
      spacing: OneirSpace.sm,
      runSpacing: OneirSpace.sm,
      children: [
        for (final reason in QuickReason.values)
          Material(
            color: OneirColors.inputFill,
            borderRadius: BorderRadius.circular(OneirRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(OneirRadius.lg),
              onTap: () => onSelected(reason),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md + 2, vertical: OneirSpace.sm + 2),
                child: Text(reason.label, style: OneirText.bodySmall.copyWith(fontWeight: FontWeight.w600, color: OneirColors.text)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final InterventionTurn turn;
  const _ChatBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: OneirSpace.xs),
        padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md + 2, vertical: OneirSpace.sm + 2),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: isUser ? OneirColors.accent : OneirColors.surfaceSunken,
          borderRadius: BorderRadius.circular(OneirRadius.md),
        ),
        child: Text(
          turn.text,
          style: OneirText.bodySmall.copyWith(color: isUser ? Colors.white : OneirColors.text),
        ),
      ),
    );
  }
}
