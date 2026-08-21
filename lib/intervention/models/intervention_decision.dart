import 'intent_category.dart';

/// What the AI decision pipeline can conclude. Kept as its own enum (rather
/// than a raw string) so the UI/state machine can exhaustively switch on it
/// -- the brief is explicit that free-form text should never be parsed
/// directly inside the UI, only this structured object.
enum InterventionDecisionType { allow, clarify, redirect }

/// The structured result of the AI decision pipeline -- the *only* thing
/// the UI and state machine act on. Mirrors the JSON shapes from the brief
/// exactly (decision/confidence/reason/estimatedMinutes/reply, plus a
/// clarifyingQuestion field for the `clarify` case).
class InterventionDecision {
  final InterventionDecisionType decision;
  final double confidence;
  final String reason;
  final String reply;
  final IntentCategory? intent;
  final int? estimatedMinutes;
  final String? clarifyingQuestion;

  const InterventionDecision({
    required this.decision,
    required this.confidence,
    required this.reason,
    required this.reply,
    this.intent,
    this.estimatedMinutes,
    this.clarifyingQuestion,
  });

  factory InterventionDecision.fromJson(Map<String, dynamic> json) {
    final rawDecision = (json['decision'] as String? ?? 'redirect').toLowerCase();
    final decision = InterventionDecisionType.values.firstWhere(
      (d) => d.name == rawDecision,
      orElse: () => InterventionDecisionType.redirect,
    );
    return InterventionDecision(
      decision: decision,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reason: json['reason'] as String? ?? '',
      reply: json['reply'] as String? ?? "Let's take a moment before deciding.",
      intent: json['intent'] != null ? IntentCategory.fromString(json['intent'] as String) : null,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      clarifyingQuestion: json['clarifyingQuestion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'decision': decision.name,
        'confidence': confidence,
        'reason': reason,
        'reply': reply,
        if (intent != null) 'intent': intent!.name,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        if (clarifyingQuestion != null) 'clarifyingQuestion': clarifyingQuestion,
      };
}
