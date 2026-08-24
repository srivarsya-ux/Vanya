import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../widgets/vanya_expression.dart';
import '../widgets_android/oneir_widget_service.dart';
import '../intervention/voice/voice_queue_controller.dart';
import '../stats/oneir_event_log.dart';

/// A real focus session -- not a placeholder. Starts a genuine countdown,
/// keeps the Quick Focus home-screen widget in sync with the real
/// remaining time, logs completed sessions for Statistics (see
/// OneirEventLog), and can be started, paused, and reset.
///
/// Per the brief's §07 ("almost boring, that's a compliment"): select
/// what you're doing, then how long, then Vanya says "I'll stay nearby,"
/// then start -- no productivity theatre. The countdown itself already
/// matched that; this adds the two setup beats that were missing before
/// it, rather than dropping the user straight into a running timer with
/// no idea what they told it they were doing.
class FocusTimeScreen extends ConsumerStatefulWidget {
  const FocusTimeScreen({super.key});

  @override
  ConsumerState<FocusTimeScreen> createState() => _FocusTimeScreenState();
}

class _FocusTimeScreenState extends ConsumerState<FocusTimeScreen> {
  static const _totalSeconds = 25 * 60;

  final _taskController = TextEditingController();

  /// Null until the setup step is completed -- this is what gates the
  /// setup screen vs. the countdown, not just "has it ever started."
  String? _task;

  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  void _confirmTask() {
    final text = _taskController.text.trim();
    setState(() => _task = text.isEmpty ? 'Focus time' : text);
    // "I'll stay nearby" -- said once, right as the session is set up, not
    // repeated on every pause/resume; a calm handoff line, not a nag.
    ref.read(voiceQueueControllerProvider.notifier).speak("I'll stay nearby.");
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
    // Pass the actual remaining time, not the default -- omitting it here
    // used to silently reset the widget's displayed countdown to a fresh
    // "25 min" on every pause, even mid-session. It also keeps a pause
    // from being mistaken for a fresh/reset session by the new
    // halfway-encouragement tracking (see updateQuickFocus).
    OneirWidgetService.updateQuickFocus(isRunning: false, remainingMinutes: (_remainingSeconds / 60).ceil());
  }

  void _finish() {
    _timer?.cancel();
    // A real completed session, logged before state resets -- Statistics'
    // "focus sessions" and total focus-time numbers come from exactly
    // this event, nothing invented on the stats screen itself.
    OneirEventLog.log(OneirEvent(
      type: OneirEventType.focusSessionCompleted,
      timestamp: DateTime.now(),
      minutes: (_totalSeconds / 60).round(),
    ));
    setState(() {
      _running = false;
      _remainingSeconds = _totalSeconds;
    });
    // completed: true, not just isRunning: false -- distinguishes "the
    // session actually finished" from _reset()'s "manually cleared" a few
    // lines below, so only a genuine finish earns the widget's "Nice
    // work." line.
    OneirWidgetService.updateQuickFocus(isRunning: false, completed: true);
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
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Focus Time', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: Center(
        child: _task == null ? _buildSetup() : _buildCountdown(),
      ),
    );
  }

  Widget _buildSetup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VanyaCharacter(expression: VanyaExpression.encouraging, width: 140, height: 140),
          const SizedBox(height: 28),
          const Text(
            'What are you doing?',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 22, color: OneirColors.text),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _taskController,
            autofocus: true,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _confirmTask(),
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: OneirColors.text),
            decoration: InputDecoration(
              hintText: 'e.g. Finish reading chapter 4',
              filled: true,
              fillColor: OneirColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            child: OneirPrimaryButton(label: 'Continue', onPressed: _confirmTask),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final progress = 1 - (_remainingSeconds / _totalSeconds);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _task!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 16, color: OneirColors.textMuted),
          ),
        ),
        const SizedBox(height: 20),
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
    );
  }
}
