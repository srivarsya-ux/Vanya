import 'ai_intervention_provider.dart';
import 'ai_provider_config.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';
import 'anthropic_provider.dart';
import 'cloud_function_provider.dart';
import 'gemma_intervention_provider.dart';
import 'offline_heuristic_provider.dart';

/// Picks the concrete provider implementation for the given config.
/// This is the one place that needs to know all six provider classes
/// exist -- everything else in the app depends only on
/// [AiInterventionProvider].
AiInterventionProvider createAiProvider(AiProviderConfig config) {
  switch (config.provider) {
    case 'gemma':
      // On-device Gemma 4 E2B -- the decided production default (see
      // AiProviderConfig.fromEnvironment). No API key, no network call at
      // inference time, nothing about what a user says leaves the device.
      return GemmaInterventionProvider();
    case 'cloud':
      // No API key needed on the client for this one -- see
      // CloudFunctionInterventionProvider's doc comment. Kept available
      // for a deployment that deliberately wants server-side inference
      // instead (e.g. a low-RAM device tier Gemma 4 E2B can't run on).
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
