import '../models/intervention_decision.dart';
import '../models/intent_category.dart';
import 'ai_intervention_provider.dart';

/// The default provider when no real AI backend is configured -- runs
/// entirely on-device, no network call, no API key. Uses simple keyword
/// heuristics rather than real language understanding, so it's
/// deliberately conservative: anything it isn't fairly confident about
/// becomes a clarifying question rather than a guess, and it only ever
/// allows access for a small set of clearly-legitimate-sounding phrases.
///
/// This exists so the intervention system is never fully non-functional
/// just because a real AI_API_KEY hasn't been configured yet -- see
/// AiProviderConfig.fromEnvironment().
class OfflineHeuristicProvider implements AiInterventionProvider {
  @override
  String get providerName => 'offline-heuristic';

  static const _messagingWords = ['message', 'text', 'reply', 'dm', 'call', 'chat with'];
  static const _homeworkWords = ['homework', 'assignment', 'submit', 'upload', 'class', 'teacher', 'lecture', 'study'];
  static const _workWords = ['work', 'boss', 'meeting', 'client', 'email', 'colleague'];
  static const _shoppingWords = ['buy', 'order', 'shopping', 'purchase', 'delivery'];
  static const _bankingWords = ['bank', 'payment', 'transfer', 'balance'];
  static const _navigationWords = ['directions', 'map', 'navigate', 'address'];
  static const _emergencyWords = ['emergency', 'urgent', 'help me', '911'];
  static const _habitWords = ['bored', 'just checking', 'quick look', 'nothing', 'idk', "don't know"];

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    final lastUserMessage = history.lastWhere((t) => t.role == 'user', orElse: () => const InterventionTurn(role: 'user', text: '')).text.toLowerCase();

    if (lastUserMessage.trim().isEmpty) {
      return InterventionDecision(
        decision: InterventionDecisionType.clarify,
        confidence: 0.3,
        reason: 'No reason given yet',
        reply: "What's bringing you to $appLabel right now?",
        clarifyingQuestion: "What's bringing you to $appLabel right now?",
      );
    }

    if (_containsAny(lastUserMessage, _emergencyWords)) {
      return InterventionDecision(
        decision: InterventionDecisionType.allow,
        confidence: 0.95,
        intent: IntentCategory.emergency,
        reason: 'Sounds urgent',
        estimatedMinutes: 15,
        reply: "Go ahead -- I hope everything's okay.",
      );
    }

    if (_containsAny(lastUserMessage, _habitWords)) {
      return InterventionDecision(
        decision: InterventionDecisionType.redirect,
        confidence: 0.7,
        intent: IntentCategory.habitScrolling,
        reason: 'Sounds like habit scrolling',
        reply: "Sounds like you're not looking for anything specific in there. Want to come back to what you were doing instead?",
      );
    }

    final matched = <IntentCategory, int>{
      IntentCategory.messaging: _countMatches(lastUserMessage, _messagingWords),
      IntentCategory.homework: _countMatches(lastUserMessage, _homeworkWords),
      IntentCategory.work: _countMatches(lastUserMessage, _workWords),
      IntentCategory.shopping: _countMatches(lastUserMessage, _shoppingWords),
      IntentCategory.banking: _countMatches(lastUserMessage, _bankingWords),
      IntentCategory.navigation: _countMatches(lastUserMessage, _navigationWords),
    };

    final best = matched.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (best.value == 0) {
      if (clarificationTurnsUsed >= 2) {
        return InterventionDecision(
          decision: InterventionDecisionType.redirect,
          confidence: 0.5,
          intent: IntentCategory.other,
          reason: 'Still unclear after clarification',
          reply: "I'm still not quite sure what you need in there -- let's come back to it later if it's not urgent.",
        );
      }
      return InterventionDecision(
        decision: InterventionDecisionType.clarify,
        confidence: 0.4,
        reason: 'Unclear intent',
        reply: 'Can you tell me a little more about what you need to do?',
        clarifyingQuestion: 'Can you tell me a little more about what you need to do?',
      );
    }

    final intent = best.key;
    final minutes = _estimateMinutes(intent, lastUserMessage);
    return InterventionDecision(
      decision: InterventionDecisionType.allow,
      confidence: 0.75,
      intent: intent,
      reason: intent.label,
      estimatedMinutes: minutes,
      reply: "I'll open $appLabel for about $minutes minute${minutes == 1 ? '' : 's'} so you can take care of that.",
    );
  }

  bool _containsAny(String text, List<String> words) => words.any((w) => text.contains(w));

  int _countMatches(String text, List<String> words) => words.where((w) => text.contains(w)).length;

  int _estimateMinutes(IntentCategory intent, String text) {
    switch (intent) {
      case IntentCategory.messaging:
        return text.contains('group') ? 6 : 3;
      case IntentCategory.homework:
        return text.contains('lecture') || text.contains('watch') ? 45 : 7;
      case IntentCategory.work:
        return 8;
      case IntentCategory.shopping:
        return 10;
      case IntentCategory.banking:
        return 5;
      case IntentCategory.navigation:
        return 4;
      default:
        return 5;
    }
  }
}
