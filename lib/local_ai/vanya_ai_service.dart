import 'package:flutter/foundation.dart';
import 'local_gemma_provider.dart';
import 'vanya_ai_provider.dart';

/// The single entry point the rest of the Vanya app should use for local,
/// on-device AI -- a thin façade over whichever [VanyaAiProvider] is
/// configured, adding status tracking (so the UI can show a spinner/error
/// without polling) and making sure the model is only ever loaded once
/// and reused, not reloaded on every screen visit.
///
/// This is intentionally separate from `lib/intervention/ai/` (the
/// existing Anthropic/OpenAI/Gemini/Cloud-Function pipeline that decides
/// real app-interruption outcomes) -- this proof-of-concept is not wired
/// into that system yet, on purpose. See the dev/test screen for where
/// this gets exercised today.
///
/// Usage:
/// ```dart
/// final service = VanyaAiService.instance;
/// await service.loadModel(onProgress: (p) => print('$p%'));
/// final reply = await service.ask('...');
/// ```
class VanyaAiService extends ChangeNotifier {
  VanyaAiService._(this._provider);

  /// Shared singleton so the (large, slow-to-load) model is loaded at
  /// most once per app run regardless of how many times the test screen
  /// is opened/closed, and so every caller sees the same status.
  static final VanyaAiService instance = VanyaAiService._(LocalGemmaProvider());

  final VanyaAiProvider _provider;

  VanyaAiStatus _status = VanyaAiStatus.notLoaded;
  VanyaAiStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  String get providerName => _provider.providerName;

  bool get isReady => _status == VanyaAiStatus.ready && _provider.isReady;
  bool get isBusy => _status == VanyaAiStatus.downloading || _status == VanyaAiStatus.loadingIntoMemory;

  Future<void> loadModel() async {
    if (isBusy) return; // already in flight, don't start a second load
    if (isReady) return; // already loaded, nothing to do

    _status = VanyaAiStatus.downloading;
    _errorMessage = null;
    _downloadProgress = 0;
    notifyListeners();

    try {
      await _provider.loadModel(
        onProgress: (progress) {
          _downloadProgress = progress;
          // A model install spends most of its time downloading; once the
          // fraction reaches 1.0 the provider moves into native loading,
          // which has no further progress signal.
          if (progress >= 1.0 && _status == VanyaAiStatus.downloading) {
            _status = VanyaAiStatus.loadingIntoMemory;
          }
          notifyListeners();
        },
      );
      _status = VanyaAiStatus.ready;
    } catch (e) {
      _status = VanyaAiStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<String> ask(String prompt) async {
    if (!isReady) {
      throw StateError('Model is not loaded yet -- call loadModel() first.');
    }
    return _provider.ask(prompt);
  }

  @override
  Future<void> dispose() async {
    await _provider.dispose();
    _status = VanyaAiStatus.notLoaded;
    super.dispose();
  }
}
