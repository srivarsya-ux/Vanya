import '../models/intervention_context.dart';
import '../models/protected_app.dart';
import '../models/temporary_access_grant.dart';
import '../models/vanya_decision.dart';
import 'intervention_history_service.dart';
import 'task_service.dart';
import 'temporary_access_service.dart';
import 'vanya_reasoning_service.dart';

/// Orchestrates the intervention lifecycle:
///
/// protected app open request -> check temporary access -> if valid,
/// allow -> otherwise retrieve current/next task -> construct
/// [InterventionContext] -> UI shows the intervention -> user gives a
/// reason -> submit -> UI shows a loading state -> reasoning service
/// evaluates -> [VanyaDecision] returned -> UI shows the response ->
/// user acts on it (for temporary access, explicitly confirms) ->
/// intervention finishes.
///
/// This class only knows [TaskService], [TemporaryAccessService],
/// [InterventionHistoryService] and the [VanyaReasoningService] interface
/// — never a UI widget, never a concrete reasoning implementation — so
/// swapping the mock reasoning service for a real one doesn't touch it.
class InterventionFlowService {
  InterventionFlowService({
    required this.taskService,
    required this.temporaryAccessService,
    required this.historyService,
    required this.reasoningService,
    this.decisionSource = 'mock_reasoning',
  });

  final TaskService taskService;
  final TemporaryAccessService temporaryAccessService;
  final InterventionHistoryService historyService;
  final VanyaReasoningService reasoningService;

  /// Recorded on every `TemporaryAccessGrant` this flow creates. Set to
  /// something else (e.g. `'actual_reasoning'`) once a real
  /// [VanyaReasoningService] replaces the mock.
  final String decisionSource;

  /// Checks temporary access and, if none is active, builds the context an
  /// intervention screen needs. Returns null when the app should just be
  /// allowed immediately — the caller shouldn't show an intervention at all
  /// in that case.
  InterventionContext? prepareIntervention(ProtectedApp app, {DateTime? at}) {
    final moment = at ?? DateTime.now();
    if (temporaryAccessService.hasActiveAccess(app.packageName, at: moment)) {
      return null;
    }
    return InterventionContext(
      protectedApp: app,
      currentTime: moment,
      currentTask: taskService.getCurrentTask(at: moment),
      nextTask: taskService.getNextTask(at: moment),
      recentInterventions: historyService.recent,
    );
  }

  /// Evaluates the (now reason-filled) context and records it to history.
  /// Deliberately does *not* create a temporary-access grant itself —
  /// per the product brief, the grant is only created once the user
  /// explicitly confirms it (see [confirmTemporaryAccess]), not the moment
  /// a decision comes back.
  Future<VanyaDecision> resolve(InterventionContext context) async {
    final decision = await reasoningService.evaluate(context);
    await historyService.record(
      InterventionHistoryEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        packageName: context.protectedApp.packageName,
        appDisplayName: context.protectedApp.displayName,
        currentTaskTitle: context.currentTask?.title,
        userReason: context.userReason,
        decisionType: decision.type,
        decisionMessage: decision.message,
        temporaryAccessDuration: decision.temporaryAccessDuration,
      ),
    );
    return decision;
  }

  /// Call when the user taps "Continue" on an
  /// [VanyaDecisionType.allowTemporaryAccess] response — this is the one
  /// point that actually creates the grant.
  Future<TemporaryAccessGrant> confirmTemporaryAccess(
    InterventionContext context,
    VanyaDecision decision,
  ) {
    assert(decision.type == VanyaDecisionType.allowTemporaryAccess);
    return temporaryAccessService.createGrant(
      packageName: context.protectedApp.packageName,
      duration: decision.temporaryAccessDuration!,
      reason: context.userReason ?? '',
      source: decisionSource,
    );
  }
}
