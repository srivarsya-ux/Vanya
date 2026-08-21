/// Caches recent utterances so identical back-to-back triggers don't
/// re-invoke the TTS engine, and so "replay" can work without the caller
/// needing to remember what was last said.
///
/// NOTE on scope: this does *not* cache synthesized audio to disk. For
/// on-device TTS (this provider) there's no real cost or latency to save
/// by doing that -- synthesis is already local and effectively instant, so
/// a file cache would add complexity (needs an audio-playback dependency
/// on top of flutter_tts) without solving a real problem. If/when a
/// network-based premium voice provider is added later (the whole reason
/// VoiceProvider is an interface, not a concrete class), *that* is when
/// disk-caching synthesized audio actually starts mattering, for both
/// cost and latency -- and it can be added inside that provider's own
/// `speak()` implementation without anything else in this file changing.
class VoiceCache {
  static const int _maxEntries = 20;
  final List<String> _recentUtterances = [];
  String? _lastSpoken;

  bool wasJustSpoken(String text) => _lastSpoken == text;

  void record(String text) {
    _lastSpoken = text;
    _recentUtterances.remove(text);
    _recentUtterances.add(text);
    if (_recentUtterances.length > _maxEntries) {
      _recentUtterances.removeAt(0);
    }
  }

  String? get lastSpoken => _lastSpoken;

  bool get hasHistory => _lastSpoken != null;
}
