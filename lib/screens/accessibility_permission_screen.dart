import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

/// Accessibility services can't be "requested" with a result callback the
/// way overlay/notification permissions can -- the user has to flip it on
/// manually in Settings. So this screen opens Settings, then watches for
/// the app resuming (the user coming back from Settings) and re-checks
/// whether the service actually got enabled, auto-advancing if so.
class AccessibilityPermissionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const AccessibilityPermissionScreen({super.key, required this.onNext, this.onBack});

  @override
  State<AccessibilityPermissionScreen> createState() => _AccessibilityPermissionScreenState();
}

class _AccessibilityPermissionScreenState extends State<AccessibilityPermissionScreen> with WidgetsBindingObserver {
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
    await OneirProtection.openAccessibilitySettings();
    // On real Android, the meaningful check happens when the app resumes
    // after the user returns from Settings (didChangeAppLifecycleState
    // below). On platforms with no native Settings screen to open at all
    // (web/desktop preview), that resume event never fires -- so also check
    // right here; on web this immediately passes through (see
    // OneirProtection.hasAccessibilityPermission), and on Android it's a
    // harmless no-op check that just won't be granted yet.
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _checking = true);
    final granted = await OneirProtection.hasAccessibilityPermission();
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
              OneirProgressHeader(progress: 13 / 18, onBack: widget.onBack),
              const Spacer(flex: 2),
              const Text('\u{1F511}', style: TextStyle(fontSize: 44)), // TODO: swap for a real Vanya illustration
              const SizedBox(height: 24),
              Text('May I help keep your promises?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 24, letterSpacing: -0.4, height: 1.35, color: OneirColors.text)),
              const SizedBox(height: 16),
              Text('So protected apps actually stay protected. This is turned on in your phone Settings, under Accessibility.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.6, color: OneirColors.textFaint)),
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
