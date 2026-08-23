import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intervention_decision.dart';
import 'ai_intervention_provider.dart';
import 'ai_provider_config.dart';
import '../services/prompt_templates.dart';
import '../services/json_extraction.dart';

class GeminiInterventionProvider implements AiInterventionProvider {
  final AiProviderConfig config;
  GeminiInterventionProvider(this.config);

  @override
  String get providerName => 'gemini';

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    final lines = history.map((t) => '${t.role == 'user' ? 'User' : 'Vanya'}: ${t.text}').toList();
    final userPrompt = InterventionPromptTemplates.buildUserPrompt(appLabel: appLabel, conversationLines: lines);

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': InterventionPromptTemplates.systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': userPrompt},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.4},
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallback('Gemini request failed (${response.statusCode})');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null) return _fallback('Empty Gemini response');

      final json = extractJsonObject(text);
      if (json == null) return _fallback('Could not parse Gemini response as JSON');
      return InterventionDecision.fromJson(json);
    } catch (e) {
      return _fallback('Gemini request error: $e');
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
