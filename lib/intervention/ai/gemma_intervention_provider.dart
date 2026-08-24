import '../../local_ai/local_gemma_provider.dart';
import '../../local_ai/vanya_ai_provider.dart';
import '../models/intervention_decision.dart';
import 'ai_intervention_provider.dart';
import '../services/prompt_templates.dart';
import '../services/json_extraction.dart';

/// The production intervention provider: Gemma 4 E2B running fully
/// on-device via [LocalGemmaProvider], wired into the same
/// [AiInterventionProvider] contract every cloud provider implements --
/// see AiProviderConfig/createAiProvider. This is the decision that was
/// unresolved in the alignment review (four provider paths wired, none
/// picked): on-device wins because §12 of the brief insists the AI stay
/// invisible and because nothing about a protected-app conversation --
/// what someone says when caught mid-scroll -- should leave the device.
///
/// [LocalGemmaProvider] itself only exposes a plain ask(String) ->
/// String chat interface (see VanyaAiProvider); this class is what
/// teaches that generic chat model to actually run the intervention
/// pipeline -- feeding it the same system + user prompt every cloud
/// provider uses (InterventionPromptTemplates), then parsing its reply
/// into the same structured [InterventionDecision] the state machine
/// already expects. Nothing downstream of [decide] knows or cares that
/// the model is local.
class GemmaInterventionProvider implements AiInterventionProvider {
  final VanyaAiProvider _model;

  /// Accepts a [VanyaAiProvider] rather than constructing [LocalGemmaProvider]
  /// directly so a test can substitute a fake model without touching real
  /// on-device inference.
  GemmaInterventionProvider({VanyaAiProvider? model}) : _model = model ?? LocalGemmaProvider();

  @override
  String get providerName => 'gemma-4-e2b-on-device';

  /// Guards concurrent decide() calls from trying to load the model twice
  /// -- the UI only ever calls decide() once at a time in practice (the
  /// state machine waits for one to finish before allowing the next), but
  /// this makes that assumption explicit rather than silent.
  Future<void>? _loadInFlight;

  Future<void> _ensureLoaded() {
    if (_model.isReady) return Future.value();
    return _loadInFlight ??= _model.loadModel().whenComplete(() => _loadInFlight = null);
  }

  @override
  Future<InterventionDecision> decide({
    required String appLabel,
    required List<InterventionTurn> history,
    required int clarificationTurnsUsed,
  }) async {
    try {
      // First call in the app's lifetime pays the one-time download +
      // load cost (see LocalGemmaProvider.loadModel's doc comment on
      // approximate size); every call after that on the same session is
      // instant because isReady short-circuits this. A generous timeout
      // here means a genuinely stuck download degrades to a clarifying
      // question instead of hanging the intervention screen's "thinking"
      // spinner forever.
      await _ensureLoaded().timeout(const Duration(seconds: 60));
    } catch (e) {
      return _fallback(
        "Vanya's on-device model isn't ready yet (${_shortMessage(e)}). "
        'This usually means the one-time model download is still in progress '
        'or needs a better connection -- try again in a moment.',
      );
    }

    final lines = history.map((t) => '${t.role == 'user' ? 'User' : 'Vanya'}: ${t.text}').toList();
    final userPrompt = InterventionPromptTemplates.buildUserPrompt(appLabel: appLabel, conversationLines: lines);

    // Gemma's chat interface (see VanyaAiProvider.ask) takes one plain
    // prompt, not a separate system-instruction field the way the Gemini/
    // OpenAI/Anthropic HTTP APIs do -- so the same system prompt every
    // other provider gets via a dedicated field is prepended here instead.
    final combinedPrompt = '${InterventionPromptTemplates.systemPrompt}\n\n$userPrompt';

    try {
      final text = await _model.ask(combinedPrompt);
      final json = extractJsonObject(text);
      if (json == null) return _fallback('Could not parse an on-device response as JSON');
      return InterventionDecision.fromJson(json);
    } catch (e) {
      return _fallback('On-device inference error: ${_shortMessage(e)}');
    }
  }

  InterventionDecision _fallback(String reason) => InterventionDecision(
        decision: InterventionDecisionType.clarify,
        confidence: 0.0,
        reason: reason,
        reply: "I'm having a little trouble thinking right now -- could you tell me again what you need?",
        clarifyingQuestion: 'Could you tell me again what you need?',
      );

  String _shortMessage(Object e) {
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}...' : s;
  }
}
