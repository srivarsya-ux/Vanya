import 'dart:async';
import 'package:flutter/material.dart';
import 'mouth_shape.dart';
import 'viseme_timeline.dart';

/// UNUSED PROTOTYPE: nothing in this app currently instantiates
/// VanyaFaceWidget -- the screen that actually renders a talking Vanya
/// (lib/intervention/widgets/intervention_conversation_screen.dart) uses
/// VanyaTalkingCharacter (lib/intervention/lipsync/) instead, which has
/// its own separate MouthCueShape-based timeline. Left in place rather
/// than deleted, same as other superseded implementations in this
/// project. Kept in sync with the same real-art swap below anyway (see
/// [MouthShapeAsset] in mouth_shape.dart) so it isn't a dead vector-art
/// relic if this simpler MouthShape/VisemeTimeline pairing ever gets
/// wired back in somewhere.
///
/// Displays the real Vanya artwork in assets/images/vanya_face/ (one
/// photo per [MouthShape], via [MouthShapeAsset]) cross-fading between
/// shapes while [isSpeaking] is true, driven by [VisemeTimeline]'s
/// estimated timing for [spokenText] -- this replaced an earlier vector
/// CustomPainter (ears/eyes/mouth drawn as Paths) once real art existed
/// to swap in, per that painter's own doc comment inviting exactly this.
/// Same external API as before (isSpeaking/spokenText/speakingRate in,
/// nothing else needed). No idle blink anymore -- the source photos
/// don't include a separate blink frame (eyes are baked into the same
/// image as the mouth), so faking one would look wrong; dropped rather
/// than shipped broken, same call made in VanyaTalkingCharacter.
class VanyaFaceWidget extends StatefulWidget {
  final bool isSpeaking;
  final String spokenText;
  final double speakingRate;
  final double size;

  const VanyaFaceWidget({
    super.key,
    required this.isSpeaking,
    required this.spokenText,
    required this.speakingRate,
    this.size = 160,
  });

  @override
  State<VanyaFaceWidget> createState() => _VanyaFaceWidgetState();
}

class _VanyaFaceWidgetState extends State<VanyaFaceWidget> {
  MouthShape _mouth = MouthShape.smile;
  Timer? _visemeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isSpeaking) _startTalking();
  }

  @override
  void didUpdateWidget(covariant VanyaFaceWidget old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking && (!old.isSpeaking || widget.spokenText != old.spokenText)) {
      _startTalking();
    } else if (!widget.isSpeaking && old.isSpeaking) {
      _stopTalking();
    }
  }

  @override
  void dispose() {
    _visemeTimer?.cancel();
    super.dispose();
  }

  void _startTalking() {
    _visemeTimer?.cancel();
    final duration = VisemeTimeline.estimateDuration(widget.spokenText, widget.speakingRate);
    final frames = VisemeTimeline.build(widget.spokenText, duration);
    if (frames.isEmpty) return;

    var index = 0;
    void scheduleNext() {
      if (!mounted || index >= frames.length) return;
      setState(() => _mouth = frames[index].shape);
      if (index + 1 < frames.length) {
        final gap = frames[index + 1].startOffset - frames[index].startOffset;
        _visemeTimer = Timer(gap < const Duration(milliseconds: 60) ? const Duration(milliseconds: 60) : gap, () {
          index++;
          scheduleNext();
        });
      }
    }

    scheduleNext();
  }

  void _stopTalking() {
    _visemeTimer?.cancel();
    setState(() => _mouth = MouthShape.smile);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 90),
        child: Image.asset(
          _mouth.assetPath,
          key: ValueKey(_mouth),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
