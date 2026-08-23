import 'quick_reason.dart';
import 'intervention_context.dart';

/// A single response rule: applies to one [reason], optionally gated by a
/// [condition] on context (e.g. only offer "Ask Co-Keeper" if one exists),
/// and [build]s the actual response by reading fields off the context --
/// this is what makes dialogue personalized (references the real task/app/
/// goal) without any per-situation string being hardcoded anywhere else in
/// the app. Adding a new nuance later means adding one more _Rule to the
/// list below, in priority order -- never touching the UI or the
/// intervention screen.
class _Rule {
  final QuickReason reason;
  final bool Function(InterventionContext) condition;
  final QuickReasonResponse Function(InterventionContext) build;

  const _Rule({required this.reason, this.condition = _always, required this.build});

  static bool _always(InterventionContext ctx) => true;
}

/// The whole rules table -- read top to bottom, first matching rule for
/// the given reason wins. This is the single source of truth the brief
/// asks for: "the intervention system must be data-driven... this will
/// allow Vanya's dialogue to evolve later without rebuilding the
/// intervention UI." Evolving dialogue means editing this list.
class QuickReasonResponses {
  QuickReasonResponses._();

  static final List<_Rule> _rules = [
    _Rule(
      reason: QuickReason.openedAutomatically,
      condition: (ctx) => ctx.currentTaskLabel != null,
      build: (ctx) => QuickReasonResponse(
        dialogue: "That's okay. Let's do ${ctx.currentTaskLabel} instead for a minute.",
        actions: ctx.hasCoKeeper
            ? [InterventionAction.backToTask, InterventionAction.startShortBreak, InterventionAction.askCoKeeper]
            : [InterventionAction.backToTask, InterventionAction.startShortBreak],
      ),
    ),
    _Rule(
      reason: QuickReason.openedAutomatically,
      build: (ctx) => QuickReasonResponse(
        dialogue: "That's okay. Let's do something else for a minute.",
        actions: ctx.hasCoKeeper
            ? [InterventionAction.backToTask, InterventionAction.startShortBreak, InterventionAction.askCoKeeper]
            : [InterventionAction.backToTask, InterventionAction.startShortBreak],
      ),
    ),
    _Rule(
      reason: QuickReason.needSomethingSpecific,
      condition: (ctx) => ctx.userGoal != null,
      build: (ctx) => QuickReasonResponse(
        dialogue: "Got it. I know you're here for ${ctx.userGoal} -- go ahead, I'll check back with you.",
        actions: [InterventionAction.continueToApp],
      ),
    ),
    _Rule(
      reason: QuickReason.needSomethingSpecific,
      build: (ctx) => const QuickReasonResponse(
        dialogue: "Okay -- go ahead, I'll check back with you in a bit.",
        actions: [InterventionAction.continueToApp],
      ),
    ),
    _Rule(
      reason: QuickReason.wantShortBreak,
      build: (ctx) => const QuickReasonResponse(
        dialogue: "A short break sounds good. I'll check back in five minutes.",
        actions: [InterventionAction.startShortBreak],
      ),
    ),
    _Rule(
      reason: QuickReason.changedMind,
      build: (ctx) => const QuickReasonResponse(
        dialogue: 'Good call. Heading back.',
        actions: [InterventionAction.returnToPrevious],
      ),
    ),
  ];

  /// Resolves the response for [reason] given [context] -- the first
  /// matching rule (in table order) wins. Always returns something: if
  /// somehow no rule matches, falls back to a safe "return to previous"
  /// response rather than throwing mid-conversation.
  static QuickReasonResponse resolve(QuickReason reason, InterventionContext context) {
    for (final rule in _rules) {
      if (rule.reason == reason && rule.condition(context)) {
        return rule.build(context);
      }
    }
    return const QuickReasonResponse(
      dialogue: "Let's come back to this in a moment.",
      actions: [InterventionAction.returnToPrevious],
    );
  }
}
