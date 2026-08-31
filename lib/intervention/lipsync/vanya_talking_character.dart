import 'dart:async';
import 'dart:math' as math;
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
/// Displays the same illustrated bunny used everywhere else in the app
/// (assets/images/vanya_speaking/body.png) with a small mouth-shape image
/// ([MouthCueShapeAsset]) and a pair of independently-blinking eye images
/// layered on top at fixed relative positions -- matching the reference
/// implementation this was ported from exactly (same body art, same mouth
/// art, same 45.64%/51.45% mouth placement and 37.61%/63.39% eye
/// placement, same blink-via-vertical-squash trick). This replaced an
/// earlier version that swapped in whole photo-realistic face-crop images
/// per mouth shape (assets/images/vanya_face/, still in the repo, unused,
/// same convention as other superseded assets here) -- those photos were
/// a different character entirely from the bunny everyone else on this
/// screen already knows; this makes the AI conversation screen finally
/// look like the same Vanya as the rest of the app.
///
/// [lineColor]/[accentColor] are kept in the constructor for API
/// stability with existing call sites, but aren't used to tint anything --
/// the bunny art has its own fixed color scheme (the lavender bandana/ear
/// shading) same as before.
///
/// Body/head/position never move (per the brief) -- only the mouth overlay
/// swaps, driven by real audio playback position, and the eyes blink on
/// their own timer independent of speech, same as the reference. When
/// [isSpeaking] is false or [audio]/[lipSyncData] are null, this renders
/// Vanya idle with a closed mouth (still blinking) and plays nothing.
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

  // Blinking runs continuously on its own random-interval loop, entirely
  // independent of speech/mouth state -- ported directly from the
  // reference implementation's timing (2.2-5.2s between blinks, 120ms
  // closed). This is what makes her read as alive even mid-sentence or
  // sitting idle, not just when the mouth happens to be moving.
  static const _blinkMinMs = 2200;
  static const _blinkMaxMs = 5200;
  static const _blinkCloseMs = 120;
  bool _blinking = false;
  Timer? _blinkTimer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _syncToWidgetState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final delay = _blinkMinMs + _random.nextInt(_blinkMaxMs - _blinkMinMs);
    _blinkTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _blinking = true);
      Timer(const Duration(milliseconds: _blinkCloseMs), () {
        if (!mounted) return;
        setState(() => _blinking = false);
      });
      _scheduleBlink();
    });
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
    _blinkTimer?.cancel();
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

  // The bunny body art is 997x1720 (tall, ears-up) -- not square like the
  // old face-crop photos were. Matches the reference implementation's own
  // `height = size * (1720 / 997)` exactly, so [size] keeps meaning "width"
  // the same way it always has for existing call sites.
  static const _bodyAspect = 1720 / 997;

  @override
  Widget build(BuildContext context) {
    final width = widget.size;
    final height = width * _bodyAspect;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Image.asset('assets/images/vanya_speaking/body.png', width: width, height: height, fit: BoxFit.contain),
          Positioned(
            left: width * 0.4564,
            top: height * 0.5145,
            width: width * 0.1505,
            height: height * 0.0872,
            child: AnimatedSwitcher(
              // Matches the 90ms the reference implementation fades
              // between mouth shapes -- fast enough to read as a live
              // mouth change rather than a slideshow, without being so
              // instant it flickers between two images every viseme cue.
              duration: const Duration(milliseconds: 90),
              child: Image.asset(
                _currentShape.assetPath,
                key: ValueKey(_currentShape),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: width * 0.3761,
            top: height * 0.45,
            width: width * 0.066,
            height: height * 0.054,
            child: _BlinkingEye(image: 'assets/images/vanya_speaking/eye_left.png', closed: _blinking),
          ),
          Positioned(
            left: width * 0.6339,
            top: height * 0.45,
            width: width * 0.066,
            height: height * 0.054,
            child: _BlinkingEye(image: 'assets/images/vanya_speaking/eye_right.png', closed: _blinking),
          ),
        ],
      ),
    );
  }
}

/// One eye, drawn open by default and vertically squashed near-flat to read
/// as closed during a blink -- same trick as the reference implementation
/// (`transform: scaleY(0.12)`), which avoids needing a separate "closed
/// eye" image.
class _BlinkingEye extends StatelessWidget {
  final String image;
  final bool closed;
  const _BlinkingEye({required this.image, required this.closed});

  @override
  Widget build(BuildContext context) {
    // AnimatedScale only does uniform scaling; a blink needs the
    // vertical-only squash the reference implementation uses
    // (`transform: scaleY(0.12)`), so this animates the Y scale factor
    // directly via a Matrix4 transform instead.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: closed ? 0.12 : 1.0),
      duration: const Duration(milliseconds: 85),
      curve: Curves.easeIn,
      builder: (context, scaleY, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(1, scaleY, 1),
        child: child,
      ),
      child: Image.asset(image, fit: BoxFit.contain),
    );
  }
}
