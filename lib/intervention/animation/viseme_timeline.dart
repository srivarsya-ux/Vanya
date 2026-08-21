import 'dart:math';
import 'mouth_shape.dart';

/// One scheduled mouth shape: hold [shape] starting at [startOffset] from
/// the beginning of the utterance.
class VisemeFrame {
  final MouthShape shape;
  final Duration startOffset;
  const VisemeFrame(this.shape, this.startOffset);
}

/// Builds an approximate mouth-shape timeline for a sentence.
///
/// flutter_tts doesn't expose real phoneme/viseme timing (that requires a
/// platform-specific speech-synthesis-markup API most on-device engines
/// don't surface to Flutter), so this estimates instead: split the text
/// into syllable-ish chunks (roughly one per vowel-cluster, which is a
/// reasonable proxy for mouth-openings-per-second in natural speech),
/// spread them evenly across the segment's estimated speaking duration,
/// and assign each chunk a plausible shape based on its vowel sound where
/// one is present. This is deliberately approximate -- it's what makes
/// "she's visibly talking" true without needing real phoneme data.
class VisemeTimeline {
  VisemeTimeline._();

  static final _vowelClusterPattern = RegExp(r'[aeiouyAEIOUY]+');

  static List<VisemeFrame> build(String text, Duration estimatedDuration) {
    final clusters = _vowelClusterPattern.allMatches(text).map((m) => m.group(0)!).toList();
    if (clusters.isEmpty || estimatedDuration == Duration.zero) {
      return [VisemeFrame(MouthShape.closed, Duration.zero)];
    }

    final perFrame = Duration(microseconds: estimatedDuration.inMicroseconds ~/ clusters.length);
    final random = Random();
    final frames = <VisemeFrame>[];

    for (var i = 0; i < clusters.length; i++) {
      frames.add(VisemeFrame(_shapeFor(clusters[i], random), perFrame * i));
    }
    frames.add(VisemeFrame(MouthShape.closed, estimatedDuration));
    return frames;
  }

  static MouthShape _shapeFor(String vowelCluster, Random random) {
    final v = vowelCluster.toLowerCase();
    if (v.contains('o')) return MouthShape.o;
    if (v.contains('u') || v.contains('w')) return MouthShape.wide;
    if (v.contains('e') || v.contains('i')) return MouthShape.smile;
    if (v.contains('a')) return random.nextBool() ? MouthShape.open : MouthShape.halfOpen;
    return MouthShape.halfOpen;
  }

  /// Rough speaking-duration estimate for a sentence at a given
  /// (0.0-1.0-normalized) TTS rate -- used when the real utterance duration
  /// isn't known ahead of time. Calibrated loosely around ~150 words/minute
  /// at rate 0.5, scaling proportionally with rate.
  static Duration estimateDuration(String text, double rate) {
    final wordCount = text.trim().isEmpty ? 1 : text.trim().split(RegExp(r'\s+')).length;
    final baseWordsPerSecond = 2.5 * (rate / 0.5).clamp(0.5, 2.0);
    final seconds = wordCount / baseWordsPerSecond;
    return Duration(milliseconds: (seconds * 1000).round().clamp(200, 15000));
  }
}
