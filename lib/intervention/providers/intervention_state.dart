import '../ai/ai_intervention_provider.dart';
import '../models/intervention_decision.dart';

/// The stages the intervention conversation moves through. Named to match
/// the animation states requested in the brief (idle/listening/thinking/
/// speaking/etc.) so the animation controller can key directly off this.
enum InterventionStage {
  detecting, // accessibility service just fired, overlay is appearing
  speaking, // Vanya's opening line is being (would be) spoken
  awaitingInput, // waiting for the user to type/speak their reason
  thinking, // AI call in flight
  clarifying, // Vanya asked a follow-up, waiting for the answer
  decided, // final decision reached, showing the reply before acting
  sessionActive, // access granted, timer running
  reLockPrompt, // timer expired, "have you finished?" prompt showing
  closed, // overlay dismissed (redirected or user backed out)
}

/// Full state for one intervention conversation -- immutable, replaced
/// wholesale on each transition (standard Riverpod Notifier pattern).
class InterventionState {
  final InterventionStage stage;
  final String appLabel;
  final String packageName;
  final List<InterventionTurn> history;
  final int clarificationTurnsUsed;
  final InterventionDecision? lastDecision;
  final bool isReLockFollowUp;
  final String? error;

  const InterventionState({
    required this.stage,
    required this.appLabel,
    required this.packageName,
    this.history = const [],
    this.clarificationTurnsUsed = 0,
    this.lastDecision,
    this.isReLockFollowUp = false,
    this.error,
  });

  factory InterventionState.initial({required String appLabel, required String packageName}) {
    return InterventionState(stage: InterventionStage.detecting, appLabel: appLabel, packageName: packageName);
  }

  InterventionState copyWith({
    InterventionStage? stage,
    List<InterventionTurn>? history,
    int? clarificationTurnsUsed,
    InterventionDecision? lastDecision,
    bool? isReLockFollowUp,
    String? error,
  }) {
    return InterventionState(
      stage: stage ?? this.stage,
      appLabel: appLabel,
      packageName: packageName,
      history: history ?? this.history,
      clarificationTurnsUsed: clarificationTurnsUsed ?? this.clarificationTurnsUsed,
      lastDecision: lastDecision ?? this.lastDecision,
      isReLockFollowUp: isReLockFollowUp ?? this.isReLockFollowUp,
      error: error,
    );
  }
}
