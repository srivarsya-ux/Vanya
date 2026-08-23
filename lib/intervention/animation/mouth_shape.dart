/// The six mouth shapes referenced in the brief -- deliberately small (not
/// full phoneme-accurate viseme mapping) since the goal is "she's visibly
/// talking," not lip-sync-perfect animation. Six shapes cycling naturally
/// reads as speech; anything more granular needs real phoneme timing data
/// that flutter_tts doesn't expose.
enum MouthShape { closed, halfOpen, open, smile, o, wide }

/// Maps each shape to the real Vanya artwork now in
/// assets/images/vanya_face/ -- replacing the vector CustomPainter that
/// VanyaFaceWidget used before real art existed (see that file's history:
/// its own doc comment specifically invited this swap once art arrived).
///
/// The source set had a few near-duplicate "resting face" photos
/// (vanya_with_a_neutral_expression / _neutral_mouth / _smile all show the
/// same closed, faintly-upturned mouth); [closed] and [smile] intentionally
/// point at two different ones of those rather than collapsing them, so a
/// future pass can differentiate the art itself if the two states ever
/// need to read as visually distinct. `vanya_mouth_extra_sad.jpg` and
/// `vanya_mouth_extra_neutral_expression.jpg` came with the same upload
/// but aren't part of the six-shape speaking cycle -- not wired to
/// anything yet; they're sitting in the same asset folder for whoever
/// picks the next real spot for a "concerned" Vanya expression (the
/// interruption/check-in flow seems like the natural fit, but that's a
/// product call, not made here).
extension MouthShapeAsset on MouthShape {
  String get assetPath {
    switch (this) {
      case MouthShape.closed:
        return 'assets/images/vanya_face/vanya_mouth_closed.jpg';
      case MouthShape.halfOpen:
        return 'assets/images/vanya_face/vanya_mouth_half_open.jpg';
      case MouthShape.open:
        return 'assets/images/vanya_face/vanya_mouth_open.jpg';
      case MouthShape.smile:
        return 'assets/images/vanya_face/vanya_mouth_smile.jpg';
      case MouthShape.o:
        return 'assets/images/vanya_face/vanya_mouth_o.jpg';
      case MouthShape.wide:
        return 'assets/images/vanya_face/vanya_mouth_wide.jpg';
    }
  }
}
