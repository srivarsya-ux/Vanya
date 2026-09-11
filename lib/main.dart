import 'package:flutter/material.dart';

import 'design_system/vanya_theme.dart';
import 'dev/design_system_showcase_screen.dart';
import 'features/intervention/android_intervention_entry_screen.dart';
import 'native/vanya_permissions.dart';

void main() {
  runApp(const VanyaApp());
}

/// PHASE 1–2 STATE: the real app shell (onboarding gate, navigation,
/// persistence) hasn't been ported yet — see MIGRATION.md at the repo
/// root. `home` points at the temporary design-system showcase so the
/// whole system can be judged on a real device first, per the build order
/// in the product brief. Swap this for the real root screen once Phase 3+
/// feature work begins.
class VanyaApp extends StatelessWidget {
  const VanyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanya',
      debugShowCheckedModeBanner: false,
      theme: VanyaTheme.light(),
      darkTheme: VanyaTheme.dark(),
      home: const _RootGate(),
    );
  }
}

/// Every launch of this app's Flutter engine could be a normal user open
/// *or* `InterventionActivity` starting a fresh engine to show one
/// intervention (see `VanyaAccessibilityService`) — this is the one place
/// that tells the two apart, by asking whether Android handed this engine
/// a pending protected-package name.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  String? _pendingPackage;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final pkg = await VanyaPermissions.getPendingInterventionPackage();
    if (!mounted) return;
    setState(() {
      _pendingPackage = pkg;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pkg = _pendingPackage;
    if (pkg != null) {
      // AndroidInterventionEntryScreen wraps its own MaterialApp (it's a
      // fully separate engine instance launched by InterventionActivity),
      // so this branch is a real widget swap, not a nested app.
      return AndroidInterventionEntryScreen(packageName: pkg);
    }
    return const DesignSystemShowcaseScreen();
  }
}
