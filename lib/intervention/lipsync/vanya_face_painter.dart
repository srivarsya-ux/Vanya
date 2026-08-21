import 'package:flutter/material.dart';
import 'lip_sync_timeline.dart';

/// SUPERSEDED: VanyaTalkingCharacter no longer uses this painter -- once
/// real Vanya artwork existed (assets/images/vanya_face/, wired via
/// MouthCueShapeAsset in lip_sync_timeline.dart), it swapped this vector
/// mouth for the real photos, per this file's own original invitation to
/// do exactly that when the day came. Left in place rather than deleted,
/// consistent with how other superseded implementations in this project
/// are handled (e.g. the removed-from-flow Interactive Demo screen) --
/// still a valid fallback if the real art ever needs to be regenerated
/// or a vector-only rendering path is wanted again.
///
/// Continuous (openness, width) parameters for each discrete mouth shape --
/// rendering the mouth as ONE shape driven by two smoothly-animated
/// scalars (rather than hard-switching between different Path types) is
/// what makes real interpolation between mouth states possible, directly
/// satisfying the "no rapid flicking, interpolate between mouth states"
/// requirement rather than just holding shapes briefly.
class MouthParams {
  final double openness; // 0 = closed, 1 = fully open
  final double roundness; // 0 = narrow/puckered, 1 = wide

  const MouthParams(this.openness, this.roundness);

  static const _table = {
    MouthCueShape.closed: MouthParams(0.04, 0.32),
    MouthCueShape.a: MouthParams(1.0, 0.55),
    MouthCueShape.b: MouthParams(0.22, 0.5),
    MouthCueShape.c: MouthParams(0.5, 0.65),
    MouthCueShape.d: MouthParams(0.7, 0.4),
    MouthCueShape.ef: MouthParams(0.35, 0.22),
  };

  static MouthParams forShape(MouthCueShape shape) => _table[shape]!;

  static MouthParams lerp(MouthParams a, MouthParams b, double t) =>
      MouthParams(a.openness + (b.openness - a.openness) * t, a.roundness + (b.roundness - a.roundness) * t);
}

/// The shared vector rendering of Vanya's face. Body/head/position never
/// move (per the brief) -- ears, eyes (with blink), and a mouth rendered
/// from continuous [MouthParams] rather than a fixed set of hard-coded
/// shapes, so it can be smoothly animated between any two mouth states.
class VanyaFacePainter extends CustomPainter {
  final MouthParams mouth;
  final bool blinking;
  final Color lineColor;
  final Color accentColor;

  VanyaFacePainter({required this.mouth, required this.blinking, required this.lineColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = lineColor;

    final earW = w * 0.13, earH = h * 0.34;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.36, h * 0.22), width: earW, height: earH), stroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.64, h * 0.22), width: earW, height: earH), stroke);

    canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.32, stroke);

    final neckPath = Path()
      ..moveTo(w * 0.38, h * 0.74)
      ..lineTo(w * 0.62, h * 0.74)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();
    canvas.drawPath(neckPath, Paint()..color = accentColor);
    final neckStroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawPath(neckPath, neckStroke);

    final eyeY = h * 0.50;
    final eyeR = w * 0.018;
    if (blinking) {
      final blinkStroke = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.40, eyeY), Offset(w * 0.45, eyeY), blinkStroke);
      canvas.drawLine(Offset(w * 0.55, eyeY), Offset(w * 0.60, eyeY), blinkStroke);
    } else {
      canvas.drawCircle(Offset(w * 0.40, eyeY), eyeR, fill);
      canvas.drawCircle(Offset(w * 0.60, eyeY), eyeR, fill);
    }

    final center = Offset(w * 0.5, h * 0.62);
    final openHeight = w * 0.02 + mouth.openness * w * 0.05;
    final width = w * 0.03 + mouth.roundness * w * 0.05;

    if (mouth.openness < 0.08) {
      canvas.drawLine(Offset(center.dx - width, center.dy), Offset(center.dx + width, center.dy), stroke);
    } else {
      canvas.drawOval(Rect.fromCenter(center: center, width: width * 2, height: openHeight), fill);
    }
  }

  @override
  bool shouldRepaint(covariant VanyaFacePainter oldDelegate) {
    return oldDelegate.mouth.openness != mouth.openness || oldDelegate.mouth.roundness != mouth.roundness || oldDelegate.blinking != blinking;
  }
}
