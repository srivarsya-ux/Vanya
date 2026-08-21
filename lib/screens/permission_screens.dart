import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_permissions.dart';

/// Requests the real OS permission (via [OneirPermissions]) when the user
/// taps Allow, and only advances/shows "Allowed" once it's actually granted.
class PermissionScreen extends StatefulWidget {
  final String emoji;
  final String question;
  final String reason;
  final double progress;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final Future<bool> Function()? requestPermission;

  const PermissionScreen({
    super.key,
    required this.emoji,
    required this.question,
    required this.reason,
    required this.progress,
    required this.onNext,
    this.onBack,
    this.requestPermission,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _allowed = false;
  bool _denied = false;

  Future<void> _handleAllow() async {
    setState(() => _denied = false);
    final granted = widget.requestPermission != null ? await widget.requestPermission!() : true;
    if (!mounted) return;
    if (granted) {
      setState(() => _allowed = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) widget.onNext();
    } else {
      setState(() => _denied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: widget.progress, onBack: widget.onBack),
              const Spacer(flex: 2),
              Text(widget.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 24),
              Text(widget.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 24, letterSpacing: -0.4, height: 1.35, color: OneirColors.text)),
              const SizedBox(height: 16),
              Text(widget.reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.6, color: OneirColors.textFaint)),
              const Spacer(flex: 3),
              if (_denied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "That's okay -- you can allow this later in your phone's Settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint),
                  ),
                ),
              _allowed
                  ? Text('\u2713 Allowed', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w500, color: OneirColors.success))
                  : OneirPrimaryButton(label: 'Allow', onPressed: _handleAllow),
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayOverAppsScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const DisplayOverAppsScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PermissionScreen(
      emoji: '\u{1F441}\uFE0F',
      question: 'May I appear before distractions?',
      reason: 'So I can gently remind you before you scroll.',
      progress: 12 / 18,
      onNext: onNext,
      onBack: onBack,
      requestPermission: OneirPermissions.requestOverlayPermission,
    );
  }
}

class NotificationsPermissionScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const NotificationsPermissionScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PermissionScreen(
      emoji: '\u{1F514}',
      question: 'May I encourage you?',
      reason: 'So I can celebrate wins and remind you kindly.',
      progress: 11 / 18,
      onNext: onNext,
      onBack: onBack,
      requestPermission: OneirPermissions.requestNotificationPermission,
    );
  }
}
