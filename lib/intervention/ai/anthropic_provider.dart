import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intervention_decision.dart';
import 'ai_intervention_provider.dart';
import 'ai_provider_config.dart';
import '../services/prompt_templates.dart';
import '../services/json_extraction.dart';

class AnthropicInterventionProvider implements AiInterventionProvider {
  final AiProviderConfig config;
  AnthropicInterventionProvider(this.config);

  @override
  String get providerName => 'anthropic';

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    final lines = history.map((t) => '${t.role == 'user' ? 'User' : 'Vanya'}: ${t.text}').toList();
    final userPrompt = InterventionPromptTemplates.buildUserPrompt(appLabel: appLabel, conversationLines: lines);

    final uri = Uri.parse('https://api.anthropic.com/v1/messages');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': config.apiKey ?? '',
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': config.model,
              'max_tokens': 300,
              'temperature': 0.4,
              'system': InterventionPromptTemplates.systemPrompt,
              'messages': [
                {'role': 'user', 'content': userPrompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallback('Anthropic request failed (${response.statusCode})');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = body['content']?[0]?['text'] as String?;
      if (text == null) return _fallback('Empty Anthropic response');

      final json = extractJsonObject(text);
      if (json == null) return _fallback('Could not parse Anthropic response as JSON');
      return InterventionDecision.fromJson(json);
    } catch (e) {
      return _fallback('Anthropic request error: $e');
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
