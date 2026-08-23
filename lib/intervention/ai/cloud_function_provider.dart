import 'package:cloud_functions/cloud_functions.dart';
import '../models/intervention_decision.dart';
import 'ai_intervention_provider.dart';

/// Calls the `decideIntervention` Firebase Cloud Function (see
/// functions/intervention.js) instead of hitting a model provider
/// directly from the client.
///
/// This is the recommended provider for anything beyond local testing:
/// [AnthropicInterventionProvider]/[OpenAiInterventionProvider]/
/// [GeminiInterventionProvider] all need their API key present inside the
/// running app (via --dart-define), which means it ships inside the
/// compiled APK and can be extracted. This provider needs no key on the
/// client at all -- the Cloud Function holds it server-side as a Firebase
/// secret, and the app just calls the function like any other Firebase
/// API.
class CloudFunctionInterventionProvider implements AiInterventionProvider {
  @override
  String get providerName => 'cloud';

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'decideIntervention',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 18)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'appLabel': appLabel,
        'history': history.map((t) => {'role': t.role, 'text': t.text}).toList(),
        'clarificationTurnsUsed': clarificationTurnsUsed,
      });

      // Callable results come back as Map<Object?, Object?> under the
      // hood on some platforms -- normalize defensively rather than
      // trusting the cast above always holds.
      final data = Map<String, dynamic>.from(result.data as Map);
      return InterventionDecision.fromJson(data);
    } catch (e) {
      return InterventionDecision(
        decision: InterventionDecisionType.clarify,
        confidence: 0.0,
        reason: 'Cloud function call failed: $e',
        reply: "I'm having a little trouble thinking right now -- could you tell me again what you need?",
        clarifyingQuestion: 'Could you tell me again what you need?',
      );
    }
  }
}
