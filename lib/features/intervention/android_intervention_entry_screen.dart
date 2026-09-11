import 'package:flutter/material.dart';

import '../../models/protected_app.dart';
import '../../models/vanya_decision.dart';
import '../../native/vanya_permissions.dart';
import '../../services/core_services.dart';
import 'intervention_controller.dart';
import 'intervention_screen.dart';

/// The root widget when this Flutter engine was started by
/// `InterventionActivity` (i.e. `VanyaAccessibilityService` detected a
/// protected app and no valid temporary access). Loads the same
/// [CoreServices] the real app uses, starts a fresh
/// [InterventionController] for [packageName], and resolves the outcome
/// back to Android through [VanyaPermissions] instead of `Navigator.pop`
/// — there's nothing meaningful to pop to here, this Activity's whole
/// purpose is this one intervention.
class AndroidInterventionEntryScreen extends StatefulWidget {
  const AndroidInterventionEntryScreen({super.key, required this.packageName});

  final String packageName;

  @override
  State<AndroidInterventionEntryScreen> createState() =>
      _AndroidInterventionEntryScreenState();
}

class _AndroidInterventionEntryScreenState
    extends State<AndroidInterventionEntryScreen> {
  InterventionController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final services = await CoreServices.load();
    final knownApp = services.protectedAppService.apps
        .where((a) => a.packageName == widget.packageName)
        .firstOrNull;
    final app = knownApp ??
        ProtectedApp(packageName: widget.packageName, displayName: widget.packageName);

    final controller = InterventionController(flow: services.flow);
    final started = controller.start(app);
    if (!mounted) return;

    if (!started) {
      // Temporary access turned out to be valid after all (a narrow race
      // between the native gate-check and this Dart-side check) — nothing
      // to show, just let the app through.
      await VanyaPermissions.finishInterventionAllow();
      return;
    }

    setState(() => _controller = controller);
  }

  Future<void> _resolve(VanyaDecision decision) async {
    switch (decision.type) {
      case VanyaDecisionType.allow:
      case VanyaDecisionType.allowTemporaryAccess:
        await VanyaPermissions.finishInterventionAllow();
      case VanyaDecisionType.redirect:
      case VanyaDecisionType.deny:
        await VanyaPermissions.finishInterventionRedirect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return InterventionScreen(controller: controller, onResolved: _resolve);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
