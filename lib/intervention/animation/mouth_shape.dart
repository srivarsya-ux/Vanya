/// The six mouth shapes referenced in the brief -- deliberately small (not
/// full phoneme-accurate viseme mapping) since the goal is "she's visibly
/// talking," not lip-sync-perfect animation. Six shapes cycling naturally
/// reads as speech; anything more granular needs real phoneme timing data
/// that flutter_tts doesn't expose.
enum MouthShape { closed, halfOpen, open, smile, o, wide }

/// Maps each shape onto the illustrated bunny mouth art in
/// assets/images/vanya_speaking/ -- replacing the earlier photo-realistic
/// face crops in assets/images/vanya_face/ (still in the repo, unused, same
/// convention as other superseded assets in this project). Those photos
/// were a completely different visual identity from the hand-drawn bunny
/// used everywhere else in the app (splash, onboarding, VanyaCharacter
/// poses) -- this swap is what makes the AI conversation screen finally
/// look like the same character as the rest of the app, using the exact
/// mouth art supplied as the reference for this.
///
/// The source set has 5 distinct mouth shapes (not 6) -- [open] and [o]
/// share `mouth_oshaped.png` (both read as "wide open" at this scale), and
/// [wide] shares `mouth_smiling_open.png` with [smile], same pattern this
/// project already uses elsewhere for near-duplicate shapes (see the old
/// mapping's own note about `closed`/`smile`). `mouth_sad.png` exists in
/// the asset folder but isn't part of this speaking cycle -- it's a
/// resting/non-speaking expression, not a viseme, and is available for
/// whoever wires a "sad" VanyaExpression later.
extension MouthShapeAsset on MouthShape {
  String get assetPath {
    switch (this) {
      case MouthShape.closed:
        return 'assets/images/vanya_speaking/mouth_neutral.png';
      case MouthShape.halfOpen:
        return 'assets/images/vanya_speaking/mouth_half_open.png';
      case MouthShape.open:
        return 'assets/images/vanya_speaking/mouth_oshaped.png';
      case MouthShape.smile:
        return 'assets/images/vanya_speaking/mouth_smiling_open.png';
      case MouthShape.o:
        return 'assets/images/vanya_speaking/mouth_oshaped.png';
      case MouthShape.wide:
        return 'assets/images/vanya_speaking/mouth_smiling_open.png';
    }
  }
}
