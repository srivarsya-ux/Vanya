import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../widgets_android/oneir_widget_service.dart';

/// A real focus session -- not a placeholder. Starts a genuine countdown,
/// keeps the Quick Focus home-screen widget in sync with the real
/// remaining time (via OneirWidgetService, built earlier alongside the
/// three real Android widgets), and can be started, paused, and reset.
class FocusTimeScreen extends StatefulWidget {
  const FocusTimeScreen({super.key});

  @override
  State<FocusTimeScreen> createState() => _FocusTimeScreenState();
}

class _FocusTimeScreenState extends State<FocusTimeScreen> {
  static const _totalSeconds = 25 * 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _finish();
        return;
      }
      setState(() => _remainingSeconds--);
      OneirWidgetService.updateQuickFocus(isRunning: true, remainingMinutes: (_remainingSeconds / 60).ceil());
    });
    OneirWidgetService.updateQuickFocus(isRunning: true, remainingMinutes: (_remainingSeconds / 60).ceil());
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
    OneirWidgetService.updateQuickFocus(isRunning: false);
  }

  void _finish() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
    OneirWidgetService.updateQuickFocus(isRunning: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nice focus session.', style: TextStyle(fontFamily: 'PlusJakartaSans'))),
      );
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
    OneirWidgetService.updateQuickFocus(isRunning: false);
  }

  String get _display {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / _totalSeconds);
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Focus Time', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: OneirColors.cardNeutral,
                    valueColor: const AlwaysStoppedAnimation(OneirColors.accent),
                  ),
                ),
                Text(_display, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 42, color: OneirColors.text)),
              ]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: OneirPrimaryButton(
                label: _running ? 'Pause' : (_remainingSeconds == _totalSeconds ? 'Start Focus' : 'Resume'),
                onPressed: _running ? _pause : _start,
              ),
            ),
            if (_remainingSeconds != _totalSeconds) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _reset,
                child: Text('Reset', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
