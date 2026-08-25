import 'dart:async';
import '../widgets/vanya_expression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';
import '../native/oneir_apps.dart';
import '../backend/co_keeper_backend.dart';
import '../backend/oneir_identity.dart';
import '../intervention/widgets/intervention_conversation_screen.dart';

/// Separate entrypoint launched by InterruptionActivity (native Android)
/// when OneirAccessibilityService detects a protected app opening. Kept
/// deliberately small and self-contained -- it does not boot the rest of
/// the app (onboarding, home, etc.), just this one screen.
///
/// Implements the graduated, adaptive-by-temptation-level flow from the
/// Co-Keeper philosophy doc: a low-attempt-count open just gets a gentle
/// check-in (cheap, no AI call -- this is the one part of the flow that was
/// already real). Repeated attempts now escalate into the REAL AI
/// conversation (InterventionConversationScreen -- the same voice+lip-sync
/// pipeline the onboarding demo already used), which is what "the actual
/// intervention" means in practice; it wasn't previously reachable from a
/// real on-device app-open at all, only from onboarding. The full
/// Co-Keeper key-request gate stays for the highest tier, and is also
/// reachable mid-conversation via that screen's own "Ask Co-Keeper" quick
/// action.
///
/// Needs a ProviderScope here (this entrypoint boots its own separate
/// widget tree from `main()`'s) since InterventionConversationScreen reads
/// Riverpod providers (interventionControllerProvider, voice, speech).
@pragma('vm:entry-point')
void interruptionMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured yet -- Co-Keeper requests will show as unavailable: $e');
  }
  final openedPackage = args.isNotEmpty ? args.first : '';
  runApp(ProviderScope(child: InterruptionApp(openedPackage: openedPackage)));
}

class InterruptionApp extends StatelessWidget {
  final String openedPackage;
  const InterruptionApp({super.key, required this.openedPackage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'PlusJakartaSans', useMaterial3: true),
      home: InterruptionScreen(openedPackage: openedPackage),
    );
  }
}

/// Tier is decided by same-day attempt count for this specific app:
/// 1st attempt -> gentle check-in only. 2nd -> also asks about their
/// intention. 3rd+ -> the full Co-Keeper gate.
enum _Tier { checkIn, intentionCheck, fullGate }

class InterruptionScreen extends StatefulWidget {
  final String openedPackage;
  const InterruptionScreen({super.key, required this.openedPackage});

  @override
  State<InterruptionScreen> createState() => _InterruptionScreenState();
}

class _InterruptionScreenState extends State<InterruptionScreen> {
  _Tier? _tier;
  String _intention = '';
  String _appLabel = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  Future<void> _setUp() async {
    final attemptCount = await OneirProtection.recordAndGetAttemptCount(widget.openedPackage);
    final intention = await OneirProtection.loadCurrentIntention();
    // The real conversation screen wants a human-readable app name ("Instagram"),
    // not the raw package string -- look it up from the same installed-apps
    // query the Protected Apps picker already uses. Fails soft to the package
    // name itself (still readable, just less polished) rather than blocking
    // the whole intervention on this one lookup.
    final installed = await OneirApps.getInstalledApps();
    final match = installed.where((a) => a.packageName == widget.openedPackage);
    if (!mounted) return;
    setState(() {
      _tier = attemptCount <= 1
          ? _Tier.checkIn
          : attemptCount == 2
              ? _Tier.intentionCheck
              : _Tier.fullGate;
      _intention = intention;
      _appLabel = match.isNotEmpty ? match.first.label : widget.openedPackage;
      _loading = false;
    });
  }

  void _goAnyway() => OneirProtection.returnToOpenedApp(); // NOTE: see method doc -- not fully real yet
  void _stayHere() => OneirProtection.returnHome();
  void _escalateToFullGate() => setState(() => _tier = _Tier.fullGate);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Colors.black26, body: Center(child: CircularProgressIndicator()));
    }

    // Tier 2 (intentionCheck) is the real, AI-backed conversation (voice +
    // lip-sync, genuine intent understanding) -- it owns its own
    // Scaffold/background, so it's returned directly rather than nested in
    // the plain white card
    // below (which is only for the cheap, no-AI first-touch check-in).
    if (_tier == _Tier.intentionCheck) {
      return InterventionConversationScreen(
        appLabel: _appLabel,
        packageName: widget.openedPackage,
        onDismiss: _stayHere,
        onLaunchApp: _goAnyway,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: Center(
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: SingleChildScrollView(
            child: switch (_tier!) {
              _Tier.checkIn => _CheckInStage(onGoAnyway: _goAnyway, onStayHere: _stayHere),
              _Tier.intentionCheck => _IntentionStage(intention: _intention, onGoAnyway: _goAnyway, onStayHere: _stayHere), // unreachable now, see build() above -- kept rather than deleted, same convention as other superseded screens in this project
              _Tier.fullGate => _FullGateStage(openedPackage: widget.openedPackage, onReturnHome: _stayHere),
            },
          ),
        ),
      ),
    );
  }
}

/// Tier 1 -- lowest friction: a quick "are you sure?" check-in.
class _CheckInStage extends StatelessWidget {
  final VoidCallback onGoAnyway;
  final VoidCallback onStayHere;
  const _CheckInStage({required this.onGoAnyway, required this.onStayHere});

  @override
  Widget build(BuildContext context) {
    // Attentive, not alarmed -- this is the lightest-touch tier (first
    // attempt today), so she's just checking in, the same way she'd
    // listen to any other question.
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const VanyaCharacter(expression: VanyaExpression.listening, width: 170, height: 203),
      const SizedBox(height: 16),
      Text('Hey there.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 18, color: OneirColors.text)),
      const SizedBox(height: 20),
      OneirPrimaryButton(label: 'Stay Here', onPressed: onStayHere),
      const SizedBox(height: 10),
      OneirSecondaryButton(label: 'Go Anyway', onPressed: onGoAnyway),
    ]);
  }
}

/// Tier 2 -- reflects their stated intention back to them before deciding.
class _IntentionStage extends StatelessWidget {
  final String intention;
  final VoidCallback onGoAnyway;
  final VoidCallback onStayHere;
  const _IntentionStage({required this.intention, required this.onGoAnyway, required this.onStayHere});

  @override
  Widget build(BuildContext context) {
    final hasIntention = intention.isNotEmpty;
    // Weighing/reflecting -- she's holding up what they told themselves
    // they'd do today against what they're doing right now, not scolding
    // them for it.
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const VanyaCharacter(expression: VanyaExpression.thinking, width: 170, height: 203),
      const SizedBox(height: 16),
      Text(
        hasIntention ? "Today's intention:\n$intention" : "You haven't set a task for today.",
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 18, color: OneirColors.text),
      ),
      const SizedBox(height: 8),
      Text('Would five more minutes on that help first?',
          textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textFaint)),
      const SizedBox(height: 20),
      OneirPrimaryButton(label: 'Stay Here', onPressed: onStayHere),
      const SizedBox(height: 10),
      OneirSecondaryButton(label: 'Go Anyway', onPressed: onGoAnyway),
    ]);
  }
}

/// Tier 3 -- the full Co-Keeper gate: real request sent over Firestore,
/// with a genuine waiting/approved/declined state instead of a fake delay.
class _FullGateStage extends StatefulWidget {
  final String openedPackage;
  final VoidCallback onReturnHome;
  const _FullGateStage({required this.openedPackage, required this.onReturnHome});

  @override
  State<_FullGateStage> createState() => _FullGateStageState();
}

enum _RequestState { notSent, pickingReason, checkingPairing, noPairing, sending, waiting, approved, declined }

const _keyRequestReasons = ['Homework', 'Urgent', 'Other'];

class _FullGateStageState extends State<_FullGateStage> {
  _RequestState _state = _RequestState.notSent;
  String? _reason;
  StreamSubscription<String>? _statusSub;

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _requestKey() async {
    setState(() => _state = _RequestState.checkingPairing);
    final coKeeperId = await OneirIdentity.getPairedCoKeeperId();
    if (coKeeperId == null) {
      setState(() => _state = _RequestState.noPairing);
      return;
    }
    setState(() => _state = _RequestState.sending);
    try {
      final requestId = await CoKeeperBackend.sendKeyRequest(
        appPackage: widget.openedPackage,
        reason: _reason ?? '',
        durationMinutes: 15,
      );
      setState(() => _state = _RequestState.waiting);
      _statusSub = CoKeeperBackend.watchRequestStatus(requestId).listen((status) {
        if (!mounted) return;
        if (status == 'approved') {
          setState(() => _state = _RequestState.approved);
        } else if (status == 'declined') {
          setState(() => _state = _RequestState.declined);
        }
      });
    } catch (_) {
      setState(() => _state = _RequestState.noPairing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      VanyaCharacter(expression: _expression(), width: 170, height: 203),
      const SizedBox(height: 16),
      Text(_headline(), textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 18, color: OneirColors.text)),
      const SizedBox(height: 20),
      ..._buttons(),
    ]);
  }

  /// This is the tier where "restraint in HOW OFTEN she reacts, not in how
  /// many expressions exist" matters most -- the full Co-Keeper gate has
  /// seven distinct real states, and until now every single one of them
  /// showed the identical idle pose. Each one gets the expression that
  /// actually matches what's happening: the shield for "protected and
  /// holding the key," the key pose for an actual unlock, a softer
  /// encouraging look for a decline rather than anything that could read
  /// as Vanya being disappointed in them.
  VanyaExpression _expression() {
    switch (_state) {
      case _RequestState.notSent:
      case _RequestState.checkingPairing:
        return VanyaExpression.protecting;
      case _RequestState.pickingReason:
        return VanyaExpression.listening;
      case _RequestState.noPairing:
        return VanyaExpression.concerned;
      case _RequestState.sending:
      case _RequestState.waiting:
        return VanyaExpression.thinking;
      case _RequestState.approved:
        return VanyaExpression.unlocking;
      case _RequestState.declined:
        return VanyaExpression.encouraging;
    }
  }

  String _headline() {
    switch (_state) {
      case _RequestState.notSent:
        return 'This app is protected.\nYour Co-Keeper is holding today\'s key.';
      case _RequestState.pickingReason:
        return "What's this for?";
      case _RequestState.checkingPairing:
        return 'This app is protected.\nYour Co-Keeper is holding today\'s key.';
      case _RequestState.noPairing:
        return "You haven't set up a Co-Keeper yet, so there's no one to ask.";
      case _RequestState.sending:
        return 'Sending request...';
      case _RequestState.waiting:
        return 'Waiting for your Co-Keeper to respond...';
      case _RequestState.approved:
        return "You've got 15 minutes. Make it count.";
      case _RequestState.declined:
        return 'Your Co-Keeper said not right now.';
    }
  }

  List<Widget> _buttons() {
    switch (_state) {
      case _RequestState.notSent:
        return [
          OneirPrimaryButton(label: 'Return to My Tasks', onPressed: widget.onReturnHome),
          const SizedBox(height: 10),
          OneirSecondaryButton(
            label: 'Request Key',
            // Ask what it's for before actually sending -- previously this
            // went straight to CoKeeperBackend.sendKeyRequest with a blank
            // reason every time, so the Co-Keeper had nothing to go on when
            // deciding whether to approve.
            onPressed: () => setState(() => _state = _RequestState.pickingReason),
          ),
        ];
      case _RequestState.pickingReason:
        return [
          for (final r in _keyRequestReasons) ...[
            OneirSelectionRow(
              label: r,
              selected: _reason == r,
              onTap: () => setState(() => _reason = r),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          OneirPrimaryButton(label: 'Send Request', onPressed: _reason == null ? null : _requestKey),
          const SizedBox(height: 10),
          OneirSecondaryButton(label: 'Back', onPressed: () => setState(() => _state = _RequestState.notSent)),
        ];
      case _RequestState.noPairing:
        return [
          OneirPrimaryButton(label: 'Return to My Tasks', onPressed: widget.onReturnHome),
        ];
      case _RequestState.checkingPairing:
      case _RequestState.sending:
      case _RequestState.waiting:
        return [const CircularProgressIndicator()];
      case _RequestState.approved:
        return [OneirPrimaryButton(label: 'Continue', onPressed: () => OneirProtection.returnToOpenedApp())];
      case _RequestState.declined:
        return [OneirPrimaryButton(label: 'Return to My Tasks', onPressed: widget.onReturnHome)];
    }
  }
}
