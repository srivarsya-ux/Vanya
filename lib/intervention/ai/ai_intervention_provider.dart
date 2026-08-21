import '../models/intervention_decision.dart';

/// Shared conversation turn shape passed to providers -- kept minimal and
/// provider-agnostic so any future provider only needs to implement one
/// method.
class InterventionTurn {
  final String role; // "user" | "assistant"
  final String text;
  const InterventionTurn({required this.role, required this.text});
}

/// Every AI backend (Gemini, OpenAI, Anthropic, or the offline default)
/// implements this single method. The rest of the app -- the state
/// machine, the UI -- never knows or cares which provider is behind it.
abstract class AiInterventionProvider {
  String get providerName;

  /// [appLabel] is the protected app being opened (e.g. "Instagram").
  /// [history] is the whole conversation so far (the user's original
  /// message plus any clarification turns). Must always return a
  /// [InterventionDecision] -- never throw a raw parsing error out to the
  /// caller; on any failure, fall back to a safe `clarify` decision so the
  /// user is asked again rather than the app crashing or silently
  /// unlocking.
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  });
}
