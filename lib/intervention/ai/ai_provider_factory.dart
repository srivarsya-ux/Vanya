import 'ai_intervention_provider.dart';
import 'ai_provider_config.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';
import 'cloud_function_provider.dart';
import 'offline_heuristic_provider.dart';

/// Picks the concrete provider implementation for the given config.
/// This is the one place that needs to know all five provider classes
/// exist -- everything else in the app depends only on
/// [AiInterventionProvider].
AiInterventionProvider createAiProvider(AiProviderConfig config) {
  switch (config.provider) {
    case 'cloud':
      // No API key needed on the client for this one -- see
      // CloudFunctionInterventionProvider's doc comment. This is the
      // recommended setting for anything beyond local dev.
      return CloudFunctionInterventionProvider();
    case 'gemini':
      return GeminiInterventionProvider(config);
    case 'openai':
      return OpenAiInterventionProvider(config);
    case 'anthropic':
      return AnthropicInterventionProvider(config);
    default:
      return OfflineHeuristicProvider();
  }
}
