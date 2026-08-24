import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_permissions.dart';

/// Step 07a -- "Usage Access". Like Accessibility, this permission has no
/// request-dialog callback; the user enables it in Settings themselves.
/// Same open-Settings-then-poll-on-resume pattern as
/// AccessibilityPermissionScreen -- kept as its own screen (not merged
/// into that one) since they're conceptually different permissions with
/// different real purposes, matching the brief's "each permission gets
/// its own explanation, do not misrepresent the permission."
class UsageAccessScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const UsageAccessScreen({super.key, required this.onNext, this.onBack});

  @override
  State<UsageAccessScreen> createState() => _UsageAccessScreenState();
}

class _UsageAccessScreenState extends State<UsageAccessScreen> with WidgetsBindingObserver {
  bool _waitingForReturn = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForReturn) {
      _waitingForReturn = false;
      _checkPermission();
    }
  }

  Future<void> _openSettings() async {
    setState(() => _waitingForReturn = true);
    await OneirPermissions.openUsageAccessSettings();
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _checking = true);
    final granted = await OneirPermissions.hasUsageAccessPermission();
    if (!mounted) return;
    setState(() => _checking = false);
    if (granted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 10 / 18, onBack: widget.onBack),
              const Spacer(flex: 2),
              const VanyaCharacter(expression: VanyaExpression.protecting, width: 168, height: 142),
              const SizedBox(height: 24),
              Text('Let me understand when protected apps are being opened.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 22, letterSpacing: -0.3, height: 1.35, color: OneirColors.text)),
              const SizedBox(height: 16),
              Text(
                "This only tells me which app is open right now -- I don't see what's inside it. Turned on in your phone's Usage Access settings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.6, color: OneirColors.textFaint),
              ),
              const Spacer(flex: 3),
              _checking
                  ? const CircularProgressIndicator()
                  : OneirPrimaryButton(label: 'Open Settings', onPressed: _openSettings),
            ],
          ),
        ),
      ),
    );
  }
}
