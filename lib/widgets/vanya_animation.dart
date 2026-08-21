import 'package:flutter/material.dart';

/// The real Vanya animation -- a hand-drawn 2-frame idle/hello loop
/// (assets/images/hello_vanya.webp), replacing OneirAssetPlaceholder
/// wherever a Vanya illustration was previously just a labeled gray box.
///
/// Only one real animation exists right now, so every call site uses this
/// same asset regardless of what pose it originally described (holding a
/// key, drinking tea, etc.) -- honest limitation, not an oversight: once
/// pose-specific art exists, individual call sites can swap this widget
/// for a pose-specific one without any layout changes, since the
/// width/height API matches what OneirAssetPlaceholder already used.
class VanyaAnimation extends StatelessWidget {
  final double width;
  final double height;

  const VanyaAnimation({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/hello_vanya.webp',
        fit: BoxFit.contain,
      ),
    );
  }
}
