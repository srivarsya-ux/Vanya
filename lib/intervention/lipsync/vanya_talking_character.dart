import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'lip_sync_timeline.dart';

enum VanyaCharacterState { idle, speaking, finished }

/// The universal, reusable Vanya-speaking component. Works with ANY
/// dialogue -- it has no idea what the text says, it just plays whatever
/// [audio] file it's given and drives the mouth from whatever
/// [lipSyncData] timeline it's given. Nothing here is dialogue-specific;
/// this is the whole point -- new dialogue never requires new animation
/// work, only a new (audio, lipSyncData) pair from the pipeline upstream.
///
/// Usage:
/// ```dart
/// VanyaTalkingCharacter(
///   audio: generatedAudioFilePath,
///   lipSyncData: generatedLipSyncTimeline,
///   isSpeaking: true,
/// )
/// ```
///
/// Displays the real Vanya artwork in assets/images/vanya_face/ (one
/// photo per [MouthCueShape], via [MouthCueShapeAsset]), cross-fading
/// between shapes as the audio position moves through [lipSyncData] --
/// this replaced the earlier vector [VanyaFacePainter] (still in this
/// package, unused, same as other superseded implementations in this
/// project) once real art existed to swap in, per that painter's own
/// invitation to do exactly this.
///
/// [lineColor]/[accentColor] are kept in the constructor for API
/// stability with existing call sites, but are no longer used to tint
/// anything -- the real artwork has its own fixed color scheme (the
/// photographed bandana etc.) that a runtime recolor can't cleanly apply
/// to a raster image the way it could to vector strokes.
///
/// Body/head/position never move (per the brief) -- the mouth is the
/// only thing that changes, driven by real audio playback position.
/// There's no independent idle blink anymore: the source art didn't come
/// with a blink frame, and faking one by reusing a mouth-shape photo
/// would look wrong (the eyes are baked into the same image as the
/// mouth), so it was dropped rather than shipped broken -- an honest gap
/// versus the earlier vector version, which could blink because eyes
/// were drawn independently of the mouth. When [isSpeaking] is false or
/// [audio]/[lipSyncData] are null, this renders Vanya idle with a closed
/// mouth and plays nothing.
class VanyaTalkingCharacter extends StatefulWidget {
  final String? audio;
  final LipSyncTimeline? lipSyncData;
  final bool isSpeaking;
  final double size;
  final Color? lineColor;
  final Color? accentColor;
  final ValueChanged<VanyaCharacterState>? onStateChanged;

  const VanyaTalkingCharacter({
    super.key,
    required this.audio,
    required this.lipSyncData,
    required this.isSpeaking,
    this.size = 160,
    this.lineColor,
    this.accentColor,
    this.onStateChanged,
  });

  @override
  State<VanyaTalkingCharacter> createState() => _VanyaTalkingCharacterState();
}

class _VanyaTalkingCharacterState extends State<VanyaTalkingCharacter> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  MouthCueShape _currentShape = MouthCueShape.closed;

  VanyaCharacterState _state = VanyaCharacterState.idle;

  @override
  void initState() {
    super.initState();
    _syncToWidgetState();
  }

  @override
  void didUpdateWidget(covariant VanyaTalkingCharacter old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking != old.isSpeaking || widget.audio != old.audio) {
      _syncToWidgetState();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _setState(VanyaCharacterState s) {
    if (_state == s) return;
    _state = s;
    widget.onStateChanged?.call(s);
  }

  Future<void> _syncToWidgetState() async {
    if (widget.isSpeaking && widget.audio != null && widget.lipSyncData != null) {
      await _startSpeaking(widget.audio!, widget.lipSyncData!);
    } else {
      await _stopAndReturnToClosed();
    }
  }

  Future<void> _startSpeaking(String audioPath, LipSyncTimeline timeline) async {
    _setState(VanyaCharacterState.speaking);

    await _positionSub?.cancel();
    await _completeSub?.cancel();

    try {
      await _player.stop();
      await _player.setSourceDeviceFile(audioPath);
      await _player.setVolume(1.0);

      _positionSub = _player.onPositionChanged.listen((position) {
        final seconds = position.inMicroseconds / 1000000.0;
        final shape = timeline.shapeAt(seconds);
        _setShape(shape);
      });

      _completeSub = _player.onPlayerComplete.listen((_) {
        _stopAndReturnToClosed();
      });

      await _player.resume();
    } catch (_) {
      await _stopAndReturnToClosed();
    }
  }

  Future<void> _stopAndReturnToClosed() async {
    await _positionSub?.cancel();
    await _completeSub?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    _setShape(MouthCueShape.closed);
    _setState(widget.isSpeaking ? VanyaCharacterState.finished : VanyaCharacterState.idle);
  }

  void _setShape(MouthCueShape shape) {
    if (_currentShape == shape) return;
    setState(() => _currentShape = shape);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        // Matches the 90ms the old vector version took to interpolate
        // between mouth shapes -- fast enough to read as a live mouth
        // change rather than a slideshow, without being so instant it
        // flickers between two photos every viseme cue.
        duration: const Duration(milliseconds: 90),
        child: Image.asset(
          _currentShape.assetPath,
          key: ValueKey(_currentShape),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
