import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intervention_decision.dart';
import 'ai_intervention_provider.dart';
import 'ai_provider_config.dart';
import '../services/prompt_templates.dart';
import '../services/json_extraction.dart';

class OpenAiInterventionProvider implements AiInterventionProvider {
  final AiProviderConfig config;
  OpenAiInterventionProvider(this.config);

  @override
  String get providerName => 'openai';

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    final lines = history.map((t) => '${t.role == 'user' ? 'User' : 'Vanya'}: ${t.text}').toList();
    final userPrompt = InterventionPromptTemplates.buildUserPrompt(appLabel: appLabel, conversationLines: lines);

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode({
              'model': config.model,
              'temperature': 0.4,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': InterventionPromptTemplates.systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallback('OpenAI request failed (${response.statusCode})');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = body['choices']?[0]?['message']?['content'] as String?;
      if (text == null) return _fallback('Empty OpenAI response');

      final json = extractJsonObject(text);
      if (json == null) return _fallback('Could not parse OpenAI response as JSON');
      return InterventionDecision.fromJson(json);
    } catch (e) {
      return _fallback('OpenAI request error: $e');
    }
  }

  InterventionDecision _fallback(String reason) => InterventionDecision(
        decision: InterventionDecisionType.clarify,
        confidence: 0.0,
        reason: reason,
        reply: "I'm having a little trouble thinking right now -- could you tell me again what you need?",
        clarifyingQuestion: 'Could you tell me again what you need?',
      );
}
