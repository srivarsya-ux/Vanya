/// Holds the API key/model for whichever AI provider is configured.
/// Intentionally simple (in-memory, set once at startup) rather than
/// pulling from a remote config service -- swap this for something more
/// sophisticated later if needed.
///
/// NOTE: none of these keys should ever be hardcoded into the app or
/// committed to source control -- they're meant to be supplied at build
/// time (e.g. via --dart-define) or read from a secure store. Shipping a
/// real API key inside a compiled APK means anyone can extract and abuse
/// it. See android_native_files/SETUP.md for how to wire this up for real.
class AiProviderConfig {
  final String provider; // "gemma" | "cloud" | "gemini" | "openai" | "anthropic" | "offline"
  final String? apiKey;
  final String model;

  const AiProviderConfig({
    required this.provider,
    this.apiKey,
    required this.model,
  });

  /// Reads from --dart-define values, e.g.:
  ///   flutter run --dart-define=AI_PROVIDER=cloud
  /// or, for local testing against a provider directly:
  ///   flutter run --dart-define=AI_PROVIDER=anthropic --dart-define=AI_API_KEY=sk-...
  ///
  /// Defaults to "gemma" (on-device Gemma 4 E2B, see
  /// GemmaInterventionProvider) when nothing is configured at all -- this
  /// is the decided production setting: no API key, no per-request cost,
  /// nothing about what a user says to Vanya leaves the device, matching
  /// the brief's "AI should be almost invisible." "offline" (the simple
  /// keyword-heuristic fallback) still exists as a safety net for a
  /// device Gemma genuinely can't run on, but is no longer the default.
  ///
  /// "cloud" and "gemma" are the two providers that need no key here at
  /// all -- "cloud" calls the decideIntervention Cloud Function, which
  /// holds the real API key server-side, for a deployment that
  /// deliberately wants server-side inference instead. The other direct
  /// provider names (anthropic/openai/gemini) exist mainly for local
  /// testing without deploying a function first.
  factory AiProviderConfig.fromEnvironment() {
    const provider = String.fromEnvironment('AI_PROVIDER', defaultValue: 'gemma');
    const apiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
    const model = String.fromEnvironment('AI_MODEL', defaultValue: '');

    if (provider == 'cloud' || provider == 'gemma' || provider == 'offline') {
      return AiProviderConfig(provider: provider, model: '');
    }

    final resolvedModel = model.isNotEmpty ? model : _defaultModelFor(provider);

    if (apiKey.isEmpty) {
      // No key configured for a direct cloud provider -- fall back to the
      // on-device default rather than making a request that will just
      // fail with an empty key.
      return const AiProviderConfig(provider: 'gemma', model: '');
    }

    return AiProviderConfig(
      provider: provider,
      apiKey: apiKey,
      model: resolvedModel,
    );
  }

  static String _defaultModelFor(String provider) {
    switch (provider) {
      case 'gemini':
        return 'gemini-1.5-flash';
      case 'openai':
        return 'gpt-4o-mini';
      case 'anthropic':
        return 'claude-3-5-haiku-20241022';
      default:
        return '';
    }
  }
}
