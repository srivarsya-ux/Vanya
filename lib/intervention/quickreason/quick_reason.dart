/// The brief's exact four quick-select reasons for opening a protected
/// app -- a fast local branch that sits alongside the free-text AI
/// conversation, not a replacement for it. Adding a fifth reason later
/// means adding one enum value + one rule (see [QuickReasonResponses]),
/// never touching the UI.
enum QuickReason { needSomethingSpecific, openedAutomatically, wantShortBreak, changedMind }

extension QuickReasonLabel on QuickReason {
  String get label {
    switch (this) {
      case QuickReason.needSomethingSpecific:
        return 'I need something specific';
      case QuickReason.openedAutomatically:
        return 'I just opened it automatically';
      case QuickReason.wantShortBreak:
        return 'I want a short break';
      case QuickReason.changedMind:
        return 'I changed my mind';
    }
  }
}

/// What Vanya can actually do in response to a quick reason -- kept as a
/// closed set of real, implemented actions rather than free-form strings,
/// so nothing here can silently reference an action that doesn't exist.
enum InterventionAction { backToTask, startShortBreak, askCoKeeper, continueToApp, returnToPrevious }

/// One resolved response: the dialogue line to speak/show, and which
/// actions the user can take from here. [dialogue] may reference the
/// context (task name, app name) -- see QuickReasonResponses for how
/// it's built, never hardcoded per-situation text.
class QuickReasonResponse {
  final String dialogue;
  final List<InterventionAction> actions;

  const QuickReasonResponse({required this.dialogue, required this.actions});
}
