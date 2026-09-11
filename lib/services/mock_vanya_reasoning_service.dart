import '../models/intervention_context.dart';
import '../models/vanya_decision.dart';
import 'vanya_reasoning_service.dart';

/// DEVELOPMENT-ONLY STAND-IN — not real AI, not a preview of real
/// judgement. Just enough deterministic keyword-matching to exercise every
/// `VanyaDecisionType` from the UI while `ActualVanyaReasoningService`
/// doesn't exist yet. [forcedDecision] lets dev tools pin a specific
/// outcome regardless of what the user typed, for scenario testing (see
/// `VanyaCoreDevScreen`).
class MockVanyaReasoningService implements VanyaReasoningService {
  MockVanyaReasoningService({this.forcedDecision});

  VanyaDecisionType? forcedDecision;

  @override
  Future<VanyaDecision> evaluate(InterventionContext context) async {
    // Simulate the latency a real network call would have, so the UI's
    // loading state ("Vanya is thinking...") actually gets exercised.
    await Future.delayed(const Duration(milliseconds: 600));

    if (forcedDecision != null) {
      return _messageFor(forcedDecision!, context);
    }

    final taskTitle = context.currentTask?.title;
    final reason = context.userReason?.trim().toLowerCase() ?? '';

    // Scenario 3 — No current task: nothing on the plan to protect, so
    // there's nothing to weigh the request against.
    if (taskTitle == null) {
      return _messageFor(VanyaDecisionType.allow, context);
    }

    // Scenario 4 — School-related need: the reason ties opening the app
    // back to the task itself (a teacher/class/assignment sent something
    // through it), so a longer supervised window makes sense.
    if (_mentionsAny(reason, ['teacher', 'class', 'assignment', 'homework', 'experiment', 'school']) &&
        _mentionsAny(reason, ['sent', 'need', 'watch', 'check', 'for '])) {
      return const VanyaDecision(
        type: VanyaDecisionType.allowTemporaryAccess,
        message: "That's a fair reason — take 10 minutes for that, then let's get back to it.",
        temporaryAccessDuration: Duration(minutes: 10),
      );
    }

    // Scenario 2 — Genuinely time-sensitive but unrelated to the task: a
    // short, explicit window rather than an open-ended yes.
    if (_mentionsAny(reason, ['friend', 'message', 'important', 'urgent', 'emergency', 'reply'])) {
      return const VanyaDecision(
        type: VanyaDecisionType.allowTemporaryAccess,
        message: "Okay — five minutes for that, then I'll check back in.",
        temporaryAccessDuration: Duration(minutes: 5),
      );
    }

    // Scenario 1 — Everything else (a generic "I just want to" with no
    // stated connection to anything urgent or task-related) — the default.
    return _messageFor(VanyaDecisionType.redirect, context);
  }

  bool _mentionsAny(String text, List<String> needles) =>
      needles.any((n) => text.contains(n));

  VanyaDecision _messageFor(VanyaDecisionType type, InterventionContext context) {
    final taskTitle = context.currentTask?.title;
    switch (type) {
      case VanyaDecisionType.redirect:
        return VanyaDecision(
          type: type,
          message: taskTitle != null
              ? "$taskTitle is on your plan right now. Want to get back to it?"
              : "Let's hold off on this one for now.",
        );
      case VanyaDecisionType.allowTemporaryAccess:
        return const VanyaDecision(
          type: VanyaDecisionType.allowTemporaryAccess,
          message: "Okay — five minutes, then I'll check back in.",
          temporaryAccessDuration: Duration(minutes: 5),
        );
      case VanyaDecisionType.allow:
        return VanyaDecision(
          type: type,
          message: taskTitle == null
              ? "Nothing's on your plan right now — go ahead."
              : 'Go ahead.',
        );
      case VanyaDecisionType.deny:
        return VanyaDecision(
          type: type,
          message: taskTitle != null
              ? "Let's not right now — $taskTitle is still waiting for you."
              : "Let's hold off on this one for now.",
        );
    }
  }
}
