/// Rhubarb Lip Sync's standard simplified mouth-shape set. Six states as
/// specified: CLOSED plus A-F. Each shape corresponds to a real class of
/// mouth openness/roundedness that natural speech cycles through --
/// deliberately NOT phoneme-exact (that needs real speech-recognition-grade
/// audio analysis), but enough distinct, meaningfully-different shapes that
/// cycling through them reads as genuine talking rather than random noise.
///
/// Mapped to VanyaFaceWidget's existing painter shapes:
///   closed -> closed (mouth shut, rest state)
///   a      -> wide-open (loud, open vowels -- "ah")
///   b      -> slightly open, teeth-together (most consonants)
///   c      -> mid-open, relaxed (soft vowels)
///   d      -> rounded open ("oh")
///   ef     -> tight rounded/puckered ("oo"/"w")
enum MouthCueShape { closed, a, b, c, d, ef }

extension MouthCueShapeLabel on MouthCueShape {
  String get rhubarbLabel {
    switch (this) {
      case MouthCueShape.closed:
        return 'CLOSED';
      case MouthCueShape.a:
        return 'A';
      case MouthCueShape.b:
        return 'B';
      case MouthCueShape.c:
        return 'C';
      case MouthCueShape.d:
        return 'D';
      case MouthCueShape.ef:
        return 'E/F';
    }
  }
}

/// Maps each cue shape to the illustrated bunny mouth art in
/// assets/images/vanya_speaking/ -- see VanyaTalkingCharacter, which draws
/// this as a small overlay positioned on top of the bunny body art, not as
/// a full-face photo swap like the earlier version. This replaced a set of
/// photo-realistic face-crop images (assets/images/vanya_face/, still in
/// the repo, unused, same convention as other superseded assets in this
/// project) that looked like a completely different character from the
/// hand-drawn bunny used everywhere else in the app -- this is what makes
/// the AI conversation screen finally look like the same Vanya.
///
/// The source set has 4 distinct speaking mouth shapes (plus an unused
/// `sad` resting expression, not part of this cycle) -- `a` (wide-open
/// "ah") and `d`/`ef` (rounded "oh"/puckered) all share
/// `mouth_oshaped.png`, and `c` (mid-open, relaxed) shares `b`'s
/// `mouth_half_open.png`, same sharing pattern this mapping already used
/// before (`ef` reused `d`).
extension MouthCueShapeAsset on MouthCueShape {
  String get assetPath {
    switch (this) {
      case MouthCueShape.closed:
        return 'assets/images/vanya_speaking/mouth_neutral.png';
      case MouthCueShape.a:
        return 'assets/images/vanya_speaking/mouth_oshaped.png';
      case MouthCueShape.b:
        return 'assets/images/vanya_speaking/mouth_half_open.png';
      case MouthCueShape.c:
        return 'assets/images/vanya_speaking/mouth_half_open.png';
      case MouthCueShape.d:
        return 'assets/images/vanya_speaking/mouth_oshaped.png';
      case MouthCueShape.ef:
        return 'assets/images/vanya_speaking/mouth_oshaped.png';
    }
  }
}

/// One scheduled mouth shape held from [start] to [end] (seconds, relative
/// to the start of the audio) -- matches the brief's exact JSON shape:
/// {"start": 0.00, "end": 0.12, "mouth": "CLOSED"}
class MouthCue {
  final double start;
  final double end;
  final MouthCueShape shape;

  const MouthCue({required this.start, required this.end, required this.shape});

  bool contains(double timeSeconds) => timeSeconds >= start && timeSeconds < end;

  Map<String, dynamic> toJson() => {'start': start, 'end': end, 'mouth': shape.rhubarbLabel};
}

/// The full, precomputed lip-sync timeline for one audio clip -- built once
/// (by [LipSyncAnalyzer]) and looked up by timestamp during playback rather
/// than recomputed on every frame. This is the object that flows from
/// LipSyncAnalyzer into VanyaTalkingCharacter.
class LipSyncTimeline {
  final List<MouthCue> cues;
  final double totalDuration;

  const LipSyncTimeline({required this.cues, required this.totalDuration});

  factory LipSyncTimeline.silent(double duration) => LipSyncTimeline(
        cues: [MouthCue(start: 0, end: duration, shape: MouthCueShape.closed)],
        totalDuration: duration,
      );

  /// Finds the mouth shape whose timeline contains [timeSeconds] -- exactly
  /// the brief's "currentAudioPosition = 2.41 -> find the cue that
  /// contains 2.41 -> display that mouth" lookup. Linear scan is fine here:
  /// a typical utterance has a few dozen cues at most, and this runs once
  /// per UI frame tick, not in a hot loop.
  MouthCueShape shapeAt(double timeSeconds) {
    for (final cue in cues) {
      if (cue.contains(timeSeconds)) return cue.shape;
    }
    return MouthCueShape.closed;
  }

  List<Map<String, dynamic>> toJson() => cues.map((c) => c.toJson()).toList();
}
