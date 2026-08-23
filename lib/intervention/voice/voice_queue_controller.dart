import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'voice_provider.dart';
import 'android_tts_provider.dart';
import 'voice_sentence_splitter.dart';
import 'voice_cache.dart';
import '../lipsync/tts_file_synthesizer.dart';
import '../lipsync/lip_sync_analyzer.dart';
import '../lipsync/lip_sync_timeline.dart';

class VoiceQueueState {
  final bool isSpeaking;
  final int totalSegments;
  final int currentSegmentIndex;
  final double rate; // 0.0 - 1.0, flutter_tts's normalized speech rate
  final String? lastFullText;
  final String? currentAudioPath;
  final LipSyncTimeline? currentLipSyncTimeline;

  const VoiceQueueState({
    this.isSpeaking = false,
    this.totalSegments = 0,
    this.currentSegmentIndex = 0,
    this.rate = 0.48, // a touch slower than the platform default (0.5), reads as calmer
    this.lastFullText,
    this.currentAudioPath,
    this.currentLipSyncTimeline,
  });

  VoiceQueueState copyWith({
    bool? isSpeaking,
    int? totalSegments,
    int? currentSegmentIndex,
    double? rate,
    String? lastFullText,
    String? currentAudioPath,
    LipSyncTimeline? currentLipSyncTimeline,
    bool clearAudio = false,
  }) {
    return VoiceQueueState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      totalSegments: totalSegments ?? this.totalSegments,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      rate: rate ?? this.rate,
      lastFullText: lastFullText ?? this.lastFullText,
      currentAudioPath: clearAudio ? null : (currentAudioPath ?? this.currentAudioPath),
      currentLipSyncTimeline: clearAudio ? null : (currentLipSyncTimeline ?? this.currentLipSyncTimeline),
    );
  }
}

/// Owns the whole speak-a-reply lifecycle: splits it into sentence
/// segments with emotional pauses, speaks them in order through whatever
/// [VoiceProvider] is configured, and supports being interrupted
/// mid-utterance (e.g. the user starts typing before Vanya finishes, or a
/// new AI decision arrives).
///
/// A monotonically increasing [_generation] token is how interruption is
/// made safe: every enqueue/interrupt bumps it, and the speak loop checks
/// it's still the current generation after every await before continuing
/// -- so an old, superseded loop can never keep talking or clobber state
/// after something newer started.
class VoiceQueueController extends Notifier<VoiceQueueState> {
  late final VoiceProvider _provider;
  late final TtsFileSynthesizer _fileSynthesizer;
  final VoiceCache _cache = VoiceCache();
  int _generation = 0;

  static const _rateKey = 'voice_speaking_rate';

  @override
  VoiceQueueState build() {
    _provider = AndroidTtsProvider();
    _fileSynthesizer = TtsFileSynthesizer();
    ref.onDispose(() {
      _provider.dispose();
      _fileSynthesizer.dispose();
    });
    _loadSavedRate();
    return const VoiceQueueState();
  }

  Future<void> _loadSavedRate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_rateKey);
    if (saved != null) state = state.copyWith(rate: saved);
  }

  Future<void> setRate(double rate) async {
    final clamped = rate.clamp(0.2, 0.9).toDouble();
    state = state.copyWith(rate: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, clamped);
  }

  /// Speaks [text], splitting it into sentence segments with pauses
  /// between them. [firstSentenceExtraPause] is for beats like the
  /// brief's "Hi." <pause> "What are you hoping to do?" opener, where the
  /// pause matters more than the punctuation alone would produce.
  Future<void> speak(String text, {Duration? firstSentenceExtraPause}) async {
    if (text.trim().isEmpty) return;

    if (_cache.wasJustSpoken(text) && state.isSpeaking) return;

    final myGeneration = ++_generation;
    await _provider.stop();

    final segments = VoiceSentenceSplitter.split(text, firstSentenceExtraPause: firstSentenceExtraPause);
    _cache.record(text);

    state = state.copyWith(isSpeaking: true, totalSegments: segments.length, currentSegmentIndex: 0, lastFullText: text);

    for (var i = 0; i < segments.length; i++) {
      if (myGeneration != _generation) return;

      state = state.copyWith(currentSegmentIndex: i);
      await _provider.speak(segments[i].text, rate: state.rate, pitch: 1.05);

      if (myGeneration != _generation) return;

      if (segments[i].pauseAfter > Duration.zero) {
        await Future.delayed(segments[i].pauseAfter);
      }
      if (myGeneration != _generation) return;
    }

    if (myGeneration == _generation) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  /// The real pipeline the brief asks for: synthesize each sentence to an
  /// actual WAV file, analyze that file's real audio for lip-sync timing,
  /// expose (audioPath, timeline) for [VanyaTalkingCharacter] to play and
  /// sync to -- replacing per-segment guesswork with real audio analysis.
  /// Sentence splitting, emotional pauses, and interruption safety are
  /// unchanged from [speak] -- only how each segment is voiced differs.
  Future<void> speakWithLipSync(String text, {Duration? firstSentenceExtraPause}) async {
    if (text.trim().isEmpty) return;
    if (_cache.wasJustSpoken(text) && state.isSpeaking) return;

    final myGeneration = ++_generation;
    await _provider.stop();

    final segments = VoiceSentenceSplitter.split(text, firstSentenceExtraPause: firstSentenceExtraPause);
    _cache.record(text);

    state = state.copyWith(isSpeaking: true, totalSegments: segments.length, currentSegmentIndex: 0, lastFullText: text, clearAudio: true);

    for (var i = 0; i < segments.length; i++) {
      if (myGeneration != _generation) return;
      state = state.copyWith(currentSegmentIndex: i);

      final audioPath = await _fileSynthesizer.synthesizeToFile(segments[i].text, rate: state.rate, pitch: 1.05);
      if (myGeneration != _generation) return;

      if (audioPath == null) {
        // Synthesis failed for this segment -- fall back to live speech
        // for just this one sentence (no lip-sync data, but the user
        // still hears the words) rather than silently skipping it.
        await _provider.speak(segments[i].text, rate: state.rate, pitch: 1.05);
      } else {
        final timeline = await LipSyncAnalyzer.analyze(audioPath, fallbackDuration: 2.0);
        if (myGeneration != _generation) return;

        state = state.copyWith(currentAudioPath: audioPath, currentLipSyncTimeline: timeline);
        // Give VanyaTalkingCharacter's own player time to actually finish
        // -- the widget plays the file independently and drives the mouth
        // from its own real position stream; this wait is purely for
        // sequencing (when to advance to the next segment/pause), not for
        // mouth timing itself.
        await Future.delayed(Duration(milliseconds: (timeline.totalDuration * 1000).round().clamp(200, 20000)));
      }

      if (myGeneration != _generation) return;
      if (segments[i].pauseAfter > Duration.zero) {
        await Future.delayed(segments[i].pauseAfter);
      }
      if (myGeneration != _generation) return;
    }

    if (myGeneration == _generation) {
      state = state.copyWith(isSpeaking: false, clearAudio: true);
    }
  }

  /// Stops speech immediately and discards any remaining queued segments
  /// -- used when the user starts typing/tapping before Vanya finishes, or
  /// when a new decision needs to interrupt whatever's currently playing.
  Future<void> interrupt() async {
    _generation++;
    await _provider.stop();
    state = state.copyWith(isSpeaking: false, clearAudio: true);
  }

  /// Re-speaks the last full utterance from the start.
  Future<void> replay() async {
    final text = _cache.lastSpoken;
    if (text == null) return;
    await interrupt();
    await speak(text);
  }

  bool get hasSomethingToReplay => _cache.hasHistory;
}

final voiceQueueControllerProvider = NotifierProvider<VoiceQueueController, VoiceQueueState>(
  VoiceQueueController.new,
);
