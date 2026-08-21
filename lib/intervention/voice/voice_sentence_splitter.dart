/// One chunk of an utterance -- spoken, then followed by [pauseAfter]
/// before the next chunk starts (or before the queue is considered done,
/// for the last segment).
class VoiceSegment {
  final String text;
  final Duration pauseAfter;
  const VoiceSegment(this.text, this.pauseAfter);
}

/// Splits a reply into sentence-sized chunks and assigns a pause after
/// each one based on its ending punctuation -- this is the "emotional
/// pauses" requirement: a question mark leaves more silence (it reads as
/// genuinely waiting for an answer), an ellipsis leaves the most, a period
/// or exclamation mark just a natural breath.
///
/// The brief's own example -- "Hi." [~2s pause] "What are you hoping to
/// do?" -- is exactly this: two short sentences with a longer pause after
/// the first because it's an opener, not just because it ends in a period.
/// That specific case is handled by [firstSentenceExtraPause] so callers
/// (the intervention state machine) can ask for that beat explicitly
/// rather than it being guessed from punctuation alone.
class VoiceSentenceSplitter {
  VoiceSentenceSplitter._();

  static const _shortPause = Duration(milliseconds: 280);
  static const _questionPause = Duration(milliseconds: 650);
  static const _ellipsisPause = Duration(milliseconds: 900);
  static const _finalPause = Duration.zero;

  static List<VoiceSegment> split(
    String text, {
    Duration? firstSentenceExtraPause,
  }) {
    if (text.trim().isEmpty) return [];

    final matches = RegExp(r'[^.!?…]+[.!?…]*').allMatches(text.trim());
    final rawSentences = matches.map((m) => m.group(0)!.trim()).where((s) => s.isNotEmpty).toList();

    if (rawSentences.isEmpty) {
      return [VoiceSegment(text.trim(), _finalPause)];
    }

    final segments = <VoiceSegment>[];
    for (var i = 0; i < rawSentences.length; i++) {
      final sentence = rawSentences[i];
      final isLast = i == rawSentences.length - 1;

      Duration pause;
      if (isLast) {
        pause = _finalPause;
      } else if (sentence.contains('…') || sentence.endsWith('...')) {
        pause = _ellipsisPause;
      } else if (sentence.endsWith('?')) {
        pause = _questionPause;
      } else {
        pause = _shortPause;
      }

      if (i == 0 && firstSentenceExtraPause != null) {
        pause = pause + firstSentenceExtraPause;
      }

      segments.add(VoiceSegment(sentence, pause));
    }
    return segments;
  }
}
