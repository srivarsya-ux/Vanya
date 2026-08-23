import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechInputState {
  final bool isListening;
  final bool isAvailable;
  final String transcript;
  final String? error;

  const SpeechInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.transcript = '',
    this.error,
  });

  SpeechInputState copyWith({bool? isListening, bool? isAvailable, String? transcript, String? error}) {
    return SpeechInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      transcript: transcript ?? this.transcript,
      error: error,
    );
  }
}

/// Wraps speech_to_text so a reply can be *spoken* into the app instead of
/// only typed -- the brief's "support text or voice replies" needs both
/// directions, and only TTS (voice out) existed before this. Kept as its
/// own small provider rather than folded into VoiceQueueController, since
/// input and output are genuinely separate concerns (and can't run at the
/// same time on most devices' microphone/speaker anyway -- the UI is
/// responsible for not listening while Vanya is talking).
class SpeechInputController extends Notifier<SpeechInputState> {
  final _speech = stt.SpeechToText();
  bool _initTried = false;

  @override
  SpeechInputState build() {
    ref.onDispose(() {
      if (_speech.isListening) _speech.stop();
    });
    return const SpeechInputState();
  }

  Future<bool> _ensureInitialized() async {
    if (state.isAvailable) return true;
    if (_initTried) return state.isAvailable;
    _initTried = true;
    try {
      final available = await _speech.initialize(
        onError: (e) => state = state.copyWith(error: e.errorMsg, isListening: false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );
      state = state.copyWith(isAvailable: available);
      return available;
    } catch (e) {
      state = state.copyWith(isAvailable: false, error: 'Speech recognition unavailable: $e');
      return false;
    }
  }

  /// Starts listening, clearing any previous transcript. Call [stopListening]
  /// (or let it auto-stop on a pause) to finish; the final transcript is
  /// left in [SpeechInputState.transcript] for the caller to read and act
  /// on (e.g. pass to the same submit flow the text field uses).
  Future<void> startListening() async {
    final available = await _ensureInitialized();
    if (!available) return;
    state = state.copyWith(isListening: true, transcript: '', error: null);
    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(transcript: result.recognizedWords);
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(partialResults: true, cancelOnError: true),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void clearTranscript() {
    state = state.copyWith(transcript: '');
  }
}

final speechInputControllerProvider = NotifierProvider<SpeechInputController, SpeechInputState>(
  SpeechInputController.new,
);
