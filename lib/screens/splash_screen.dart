import 'dart:async';
import '../widgets/vanya_animation.dart';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onNext;
  const SplashScreen({super.key, required this.onNext});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), widget.onNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: GestureDetector(
        onTap: widget.onNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              left: 51.5,
              top: 176,
              width: 248.7,
              height: 76.7,
              child: Text(
                'Vanya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w500,
                  fontSize: 50,
                  height: 1,
                  color: OneirColors.splashWordmark,
                ),
              ),
            ),
            Positioned(
              // Vanya bumped 300x361 (was 224x269.7) -- left recentered to
              // (351.7 design-width - 300) / 2 so she stays centered instead
              // of drifting right; this Positioned's own width/height must
              // match VanyaAnimation's below it exactly, since Positioned
              // clips its child to whatever box it declares regardless of
              // what size the child itself asks for.
              left: 25.85,
              top: 283.6,
              width: 300,
              height: 361,
              child: VanyaAnimation(width: 300, height: 361),
            ),
          ],
        ),
      ),
    );
  }
}
