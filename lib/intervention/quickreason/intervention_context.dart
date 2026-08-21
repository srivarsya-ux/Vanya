/// Everything that should be able to influence Vanya's response to a
/// protected-app open, per the brief: "User goal, protected app, user
/// response, current task, focus state, break state, Co-Keeper state can
/// influence the response." Bundled as one object rather than scattered
/// parameters so the response-rules table (see [QuickReasonResponses])
/// stays a pure function of (reason, context) -- easy to extend later
/// without touching the UI.
class InterventionContext {
  final String appLabel;
  final String packageName;
  final String? userGoal; // from onboarding's "why are you here" answer
  final String? currentTaskLabel; // the task they said they'd rather be doing
  final bool isFocusSessionActive;
  final bool hasCoKeeper;

  const InterventionContext({
    required this.appLabel,
    required this.packageName,
    this.userGoal,
    this.currentTaskLabel,
    this.isFocusSessionActive = false,
    this.hasCoKeeper = false,
  });
}
