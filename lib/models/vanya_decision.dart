/// What Vanya decides to do about a protected-app open. This is the one
/// object that crosses the boundary between "AI decides" and "application
/// logic acts" (see the architecture note in `VanyaReasoningService`) — the
/// application layer and, eventually, Android enforcement should only ever
/// need to branch on a [VanyaDecision], never reach back into reasoning.
enum VanyaDecisionType {
  /// Steer the user back to their current/next task instead of the app.
  redirect,

  /// Let the app open, but only for [VanyaDecision.temporaryAccessDuration]
  /// — the caller is responsible for turning this into a
  /// `TemporaryAccessGrant` via `TemporaryAccessService`.
  allowTemporaryAccess,

  /// Let the app open with no time limit.
  allow,

  /// Keep the app blocked with no temporary exception.
  deny,
}

class VanyaDecision {
  const VanyaDecision({
    required this.type,
    required this.message,
    this.temporaryAccessDuration,
  }) : assert(
          type != VanyaDecisionType.allowTemporaryAccess ||
              temporaryAccessDuration != null,
          'allowTemporaryAccess requires a temporaryAccessDuration',
        );

  final VanyaDecisionType type;

  /// Vanya's response shown to the user — e.g. "You planned science for
  /// now. Want to get that done first?"
  final String message;

  /// Only set when [type] is [VanyaDecisionType.allowTemporaryAccess].
  final Duration? temporaryAccessDuration;
}
