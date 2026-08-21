/// Status of the on-device AI model lifecycle, surfaced to the UI so it
/// can show a status indicator without knowing anything about Gemma or
/// flutter_gemma specifically.
enum VanyaAiStatus {
  notLoaded,
  downloading,
  loadingIntoMemory,
  ready,
  error,
}

/// Contract every on-device model backend implements. [VanyaAiService]
/// (and everything above it -- the dev/test screen today, the real Vanya
/// "brain" later) only ever talks to this interface, never to a specific
/// model package directly:
///
/// ```
/// Vanya UI
///    |
/// VanyaAiService        (this file's caller -- status tracking, one
///    |                   shared instance, never talks to Gemma directly)
/// VanyaAiProvider        (this interface)
///    |
/// LocalGemmaProvider     (today's implementation)
///    |
/// Gemma 4 E2B
/// ```
///
/// Swapping Gemma 4 E2B for a different local model later means writing
/// one new class that implements this interface and pointing
/// [VanyaAiService] at it in its constructor -- nothing else in the app
/// (the UI, the eventual intervention logic) needs to change.
abstract class VanyaAiProvider {
  String get providerName;

  /// Downloads (if not already cached) and loads the model into memory.
  /// [onProgress] is called with a 0.0-1.0 fraction during download;
  /// implementations may stop reporting progress once the download
  /// finishes and native loading begins, since that phase has no
  /// fine-grained progress to report.
  ///
  /// Must not be called again while a previous call is still in flight.
  /// Should be safe to call again after a failed attempt (retries) or
  /// after [dispose] (reload).
  Future<void> loadModel({void Function(double progress)? onProgress});

  /// Whether [loadModel] has completed successfully and the model is
  /// currently loaded and ready for [ask].
  bool get isReady;

  /// Runs one prompt through the loaded model and returns its full text
  /// response. Only valid after [isReady] is true. Implementations must
  /// not let a raw platform/plugin exception escape uncaught in a way the
  /// caller can't show to the user -- catch it and rethrow a plain
  /// [Exception] with a human-readable message instead.
  Future<String> ask(String prompt);

  /// Releases native model/session resources. Safe to call even if the
  /// model was never loaded or already disposed.
  Future<void> dispose();
}
