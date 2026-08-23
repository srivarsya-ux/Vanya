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

/// Maps each cue shape to the real Vanya artwork in
/// assets/images/vanya_face/ (see VanyaTalkingCharacter, which now
/// displays this asset per shape instead of driving VanyaFacePainter's
/// vector mouth -- that painter and its continuous MouthParams table are
/// unused now but left in place rather than deleted, same as other
/// superseded implementations in this project).
///
/// The mapping follows this file's own doc comment above (closed -> rest,
/// a -> wide-open "ah", b -> slightly open, c -> mid-open, d -> rounded
/// "oh") using the closest real photo for each. There's no distinct
/// "tight rounded/puckered" photo for `ef` in the source set, so it
/// reuses the `d` ("oh") shape -- the closest available rounded mouth --
/// rather than inventing a sixth image; a real `ef`/"oo" photo would be a
/// clean drop-in if one ever gets drawn.
extension MouthCueShapeAsset on MouthCueShape {
  String get assetPath {
    switch (this) {
      case MouthCueShape.closed:
        return 'assets/images/vanya_face/vanya_mouth_closed.jpg';
      case MouthCueShape.a:
        return 'assets/images/vanya_face/vanya_mouth_wide.jpg';
      case MouthCueShape.b:
        return 'assets/images/vanya_face/vanya_mouth_half_open.jpg';
      case MouthCueShape.c:
        return 'assets/images/vanya_face/vanya_mouth_open.jpg';
      case MouthCueShape.d:
        return 'assets/images/vanya_face/vanya_mouth_o.jpg';
      case MouthCueShape.ef:
        return 'assets/images/vanya_face/vanya_mouth_o.jpg';
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
