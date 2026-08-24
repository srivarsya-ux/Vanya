import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_intervention_provider.dart';
import '../ai/ai_provider_config.dart';
import '../ai/ai_provider_factory.dart';
import '../models/intervention_decision.dart';
import '../services/unlock_scheduler.dart';
import '../voice/voice_queue_controller.dart';
import '../../stats/oneir_event_log.dart';
import 'intervention_state.dart';

/// The onboarding demo (AiInterventionDemoScreen) reuses this exact same
/// controller/pipeline against a fake package name so a new user can talk
/// to the real Vanya before finishing setup -- see that screen's doc
/// comment. Its decisions are real AI output but not a real protected-app
/// event, so they're excluded here rather than quietly inflating a new
/// user's very first Statistics numbers with a demo conversation.
const _demoPackageName = 'com.oneir.onboarding_demo';

/// The one Riverpod provider the UI talks to. Owns the whole conversation:
/// intent detection -> (optional) clarification loop (max 2 turns) ->
/// decision -> acting on that decision (starting a timed session, or
/// closing the overlay with a redirect message).
///
/// Also owns triggering voice at each beat -- every reply Vanya "says" in
/// the state machine is spoken through VoiceQueueController, not just
/// displayed as text.
class InterventionController extends Notifier<InterventionState?> {
  late final AiInterventionProvider _ai;

  @override
  InterventionState? build() {
    _ai = createAiProvider(AiProviderConfig.fromEnvironment());
    ref.onDispose(() {});
    return null;
  }

  /// Called by the native side (via InterruptionActivity's Dart entrypoint)
  /// when a protected app is opened, or by the re-lock timer when a
  /// session expires.
  void start({required String appLabel, required String packageName, bool isReLockFollowUp = false}) {
    state = InterventionState.initial(appLabel: appLabel, packageName: packageName).copyWith(
      stage: isReLockFollowUp ? InterventionStage.reLockPrompt : InterventionStage.speaking,
      isReLockFollowUp: isReLockFollowUp,
    );

    if (isReLockFollowUp) {
      ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync('Have you finished?');
    } else {
      // The brief's own example: "Hi." <~2s pause> "What are you hoping to
      // do?" -- the extra pause after the opener is what makes it feel
      // like someone waiting for an answer, not a script firing off lines.
      ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(
            'Hi. What are you hoping to do?',
            firstSentenceExtraPause: const Duration(milliseconds: 1400),
          );
    }
  }

  /// Moves from the opening line to actually waiting for the user's
  /// explanation -- kept as a separate step so the UI can show the
  /// speaking animation for a beat before the input field appears.
  void readyForInput() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(stage: InterventionStage.awaitingInput);
  }

  /// Submits the user's explanation (their initial reason, or an answer to
  /// a clarifying question) and runs it through the AI decision pipeline.
  Future<void> submitUserMessage(String text) async {
    final s = state;
    if (s == null || text.trim().isEmpty) return;

    // The user is talking -- Vanya shouldn't be mid-sentence over them.
    await ref.read(voiceQueueControllerProvider.notifier).interrupt();

    final wasClarifying = s.stage == InterventionStage.clarifying;
    final newHistory = [...s.history, InterventionTurn(role: 'user', text: text.trim())];

    state = s.copyWith(
      stage: InterventionStage.thinking,
      history: newHistory,
      clarificationTurnsUsed: wasClarifying ? s.clarificationTurnsUsed + 1 : s.clarificationTurnsUsed,
    );

    final decision = await _ai.decide(
      appLabel: s.appLabel,
      history: newHistory,
      clarificationTurnsUsed: state!.clarificationTurnsUsed,
    );

    final withReply = [...newHistory, InterventionTurn(role: 'assistant', text: decision.reply)];

    if (decision.decision == InterventionDecisionType.clarify && state!.clarificationTurnsUsed < 2) {
      state = state!.copyWith(stage: InterventionStage.clarifying, history: withReply, lastDecision: decision);
      ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(decision.reply);
      return;
    }

    state = state!.copyWith(stage: InterventionStage.decided, history: withReply, lastDecision: decision);
    ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(decision.reply);
    _logDecision(s, decision);

    if (decision.decision == InterventionDecisionType.allow) {
      final minutes = decision.estimatedMinutes ?? 5;
      await UnlockScheduler.instance.startSession(
        packageName: s.packageName,
        duration: Duration(minutes: minutes),
        reason: decision.reason,
      );
      state = state!.copyWith(stage: InterventionStage.sessionActive);
    }
  }

  /// Statistics' only real data source (see OneirEventLog) -- logs an
  /// `allow` or `redirect` outcome the moment it's actually decided.
  /// `clarify` isn't logged (it isn't a finished outcome yet), and the
  /// onboarding demo's fake package is excluded (see _demoPackageName).
  void _logDecision(InterventionState s, InterventionDecision decision) {
    if (s.packageName == _demoPackageName) return;
    switch (decision.decision) {
      case InterventionDecisionType.redirect:
        OneirEventLog.log(OneirEvent(
          type: OneirEventType.interventionRedirect,
          timestamp: DateTime.now(),
          appLabel: s.appLabel,
          packageName: s.packageName,
        ));
        break;
      case InterventionDecisionType.allow:
        OneirEventLog.log(OneirEvent(
          type: OneirEventType.interventionAllow,
          timestamp: DateTime.now(),
          appLabel: s.appLabel,
          packageName: s.packageName,
          minutes: decision.estimatedMinutes,
        ));
        break;
      case InterventionDecisionType.clarify:
        break;
    }
  }

  /// "Have you finished?" -> yes: end the session and re-lock.
  Future<void> confirmSessionFinished() async {
    final s = state;
    if (s == null) return;
    await ref.read(voiceQueueControllerProvider.notifier).interrupt();
    await UnlockScheduler.instance.endSession(s.packageName);
    state = s.copyWith(stage: InterventionStage.closed);
  }

  /// "Have you finished?" -> no: let them explain briefly, then re-run the
  /// decision pipeline for a possible extension rather than granting one
  /// automatically.
  Future<void> requestMoreTime(String explanation) async {
    final s = state;
    if (s == null) return;
    await ref.read(voiceQueueControllerProvider.notifier).interrupt();
    final newHistory = [...s.history, InterventionTurn(role: 'user', text: explanation.trim())];
    state = s.copyWith(stage: InterventionStage.thinking, history: newHistory);

    final decision = await _ai.decide(appLabel: s.appLabel, history: newHistory, clarificationTurnsUsed: 0);
    final withReply = [...newHistory, InterventionTurn(role: 'assistant', text: decision.reply)];
    ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(decision.reply);

    if (decision.decision == InterventionDecisionType.allow) {
      final extraMinutes = decision.estimatedMinutes ?? 5;
      await UnlockScheduler.instance.extendSession(s.packageName, Duration(minutes: extraMinutes));
      state = state!.copyWith(stage: InterventionStage.sessionActive, history: withReply, lastDecision: decision);
    } else {
      state = state!.copyWith(stage: InterventionStage.decided, history: withReply, lastDecision: decision);
    }
    _logDecision(s, decision);
  }

  Future<void> close() async {
    final s = state;
    if (s == null) return;
    await ref.read(voiceQueueControllerProvider.notifier).interrupt();
    state = s.copyWith(stage: InterventionStage.closed);
  }
}

final interventionControllerProvider = NotifierProvider<InterventionController, InterventionState?>(
  InterventionController.new,
);
