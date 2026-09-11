import 'package:flutter/foundation.dart';

import '../../models/intervention_context.dart';
import '../../models/protected_app.dart';
import '../../models/vanya_decision.dart';
import '../../services/intervention_flow_service.dart';

enum InterventionPhase {
  /// No intervention in progress.
  idle,

  /// Context built, waiting on the user to type a reason and submit.
  awaitingReason,

  /// Reason submitted, `VanyaReasoningService` is evaluating.
  reasoning,

  /// A `VanyaDecision` came back — showing the response.
  decided,

  /// The reasoning service threw — showing the safe fallback state.
  error,
}

/// The single state manager for the intervention lifecycle — the widget
/// tree only ever observes this, it never runs the flow itself. Wraps
/// [InterventionFlowService] with everything a screen needs to render:
/// which phase it's in, the app that triggered it, the built context, what
/// the user typed, and the resulting decision.
class InterventionController extends ChangeNotifier {
  InterventionController({required this.flow});

  final InterventionFlowService flow;

  InterventionPhase _phase = InterventionPhase.idle;
  InterventionPhase get phase => _phase;

  bool get isActive => _phase != InterventionPhase.idle;

  ProtectedApp? _protectedApp;
  ProtectedApp? get protectedApp => _protectedApp;

  InterventionContext? _context;
  InterventionContext? get context => _context;

  String _userReason = '';
  String get userReason => _userReason;

  VanyaDecision? _decision;
  VanyaDecision? get decision => _decision;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Step 1-4 of the lifecycle: protected-app open request -> check
  /// temporary access -> (if valid, the caller should stop here — this
  /// returns false and nothing is shown) -> retrieve current/next task ->
  /// construct [InterventionContext].
  ///
  /// Returns true when an intervention should actually be shown.
  bool start(ProtectedApp app) {
    final context = flow.prepareIntervention(app);
    if (context == null) {
      reset();
      return false;
    }
    _protectedApp = app;
    _context = context;
    _userReason = '';
    _decision = null;
    _errorMessage = null;
    _phase = InterventionPhase.awaitingReason;
    notifyListeners();
    return true;
  }

  void updateReason(String value) {
    _userReason = value;
  }

  /// Submit -> loading state -> reasoning service evaluates -> decision
  /// received (or the safe error fallback). Guarded on [_phase] so a
  /// double-tap on Submit can't fire two overlapping reasoning calls —
  /// only the first submit while [InterventionPhase.awaitingReason]
  /// actually does anything.
  Future<void> submitReason() async {
    if (_phase != InterventionPhase.awaitingReason || _context == null) return;
    final contextWithReason = _context!.copyWith(userReason: _userReason);
    _context = contextWithReason;
    _phase = InterventionPhase.reasoning;
    notifyListeners();

    try {
      final decision = await flow.resolve(contextWithReason);
      _decision = decision;
      _phase = InterventionPhase.decided;
    } catch (e) {
      _errorMessage = e.toString();
      _phase = InterventionPhase.error;
    }
    notifyListeners();
  }

  /// Only point that actually creates a `TemporaryAccessGrant` — called
  /// when the user taps "Continue" on an allowTemporaryAccess response,
  /// never automatically the moment the decision arrives.
  Future<void> confirmTemporaryAccess() async {
    final context = _context;
    final decision = _decision;
    if (context == null ||
        decision == null ||
        decision.type != VanyaDecisionType.allowTemporaryAccess) {
      return;
    }
    await flow.confirmTemporaryAccess(context, decision);
  }

  /// Back to the reason form after an error, without losing what the user
  /// already typed.
  void retry() {
    if (_phase != InterventionPhase.error) return;
    _errorMessage = null;
    _phase = InterventionPhase.awaitingReason;
    notifyListeners();
  }

  /// Clears all intervention state — call when leaving the intervention
  /// screen (whatever the outcome) so a later intervention never starts
  /// from stale state.
  void reset() {
    _phase = InterventionPhase.idle;
    _protectedApp = null;
    _context = null;
    _userReason = '';
    _decision = null;
    _errorMessage = null;
    notifyListeners();
  }
}
