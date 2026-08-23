import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_provider.dart';

/// Wraps the platform's built-in TextToSpeech engine (Android's
/// TextToSpeech / iOS's AVSpeechSynthesizer, via the flutter_tts plugin).
/// This is what the brief calls "Android TTS is enough for Version 1" --
/// no premium/cloud voice yet, just the device's own synthesizer.
class AndroidTtsProvider implements VoiceProvider {
  final FlutterTts _tts = FlutterTts();
  final _eventsController = StreamController<VoiceEvent>.broadcast();
  bool _isSpeaking = false;
  bool _initialized = false;

  @override
  String get providerName => 'android-tts';

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<VoiceEvent> get events => _eventsController.stream;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      _eventsController.add(const VoiceEvent(VoiceEventType.started));
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _eventsController.add(const VoiceEvent(VoiceEventType.completed));
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _eventsController.add(const VoiceEvent(VoiceEventType.cancelled));
    });
    _tts.setErrorHandler((message) {
      _isSpeaking = false;
      _eventsController.add(VoiceEvent(VoiceEventType.error, message));
    });
  }

  @override
  Future<void> speak(String text, {required double rate, required double pitch}) async {
    await _ensureInitialized();
    if (text.trim().isEmpty) return;

    // flutter_tts's rate is 0.0-1.0 (platform-normalized), not
    // words-per-minute -- callers pass a 0.0-1.0 value already (see
    // VoiceQueueController's speakingRate).
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0).toDouble());
    await _tts.setPitch(pitch.clamp(0.5, 2.0).toDouble());
    await _tts.setVolume(1.0);

    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _ensureInitialized();
    await _tts.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
    await _eventsController.close();
  }
}
