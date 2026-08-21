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
  final String provider; // "cloud" | "gemini" | "openai" | "anthropic" | "offline"
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
  /// Falls back to the offline provider (no key needed) if nothing is
  /// configured, so the app always runs rather than crashing on a missing
  /// key.
  ///
  /// "cloud" is the one provider that needs no key here at all -- it
  /// calls the decideIntervention Cloud Function, which holds the real
  /// API key server-side. That's the setting anything shipped should use;
  /// the direct provider names (anthropic/openai/gemini) exist mainly for
  /// local testing without deploying a function first.
  factory AiProviderConfig.fromEnvironment() {
    const provider = String.fromEnvironment('AI_PROVIDER', defaultValue: 'offline');
    const apiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
    const model = String.fromEnvironment('AI_MODEL', defaultValue: '');

    if (provider == 'cloud') {
      return const AiProviderConfig(provider: 'cloud', model: '');
    }

    final resolvedModel = model.isNotEmpty ? model : _defaultModelFor(provider);

    if (apiKey.isEmpty && provider != 'offline') {
      // No key configured for a direct provider -- fall back to offline
      // rather than making a request that will just fail.
      return const AiProviderConfig(provider: 'offline', model: '');
    }

    return AiProviderConfig(
      provider: provider,
      apiKey: apiKey.isEmpty ? null : apiKey,
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
