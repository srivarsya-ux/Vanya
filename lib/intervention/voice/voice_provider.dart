/// Fires as speech progresses -- the queue controller listens to these to
/// know when it's safe to start the next queued sentence.
enum VoiceEventType { started, completed, cancelled, error }

class VoiceEvent {
  final VoiceEventType type;
  final String? message;
  const VoiceEvent(this.type, [this.message]);
}

/// Every voice backend (on-device Android TTS now, a premium cloud voice
/// later) implements this one interface. Nothing else in the app -- the
/// queue controller, the UI -- ever talks to a concrete engine directly,
/// so swapping "Android TTS" for "ElevenLabs" or similar later is a
/// one-file change (a new provider + one line in the factory), matching
/// the same abstraction pattern already used for the AI decision
/// providers.
abstract class VoiceProvider {
  String get providerName;

  /// Must complete only once speech has *finished* (or been stopped) --
  /// callers rely on this to sequence a queue of sentences.
  Future<void> speak(String text, {required double rate, required double pitch});

  Future<void> stop();

  bool get isSpeaking;

  /// Emits lifecycle events for the currently-speaking utterance.
  Stream<VoiceEvent> get events;

  Future<void> dispose();
}
