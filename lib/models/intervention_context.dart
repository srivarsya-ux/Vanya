import 'protected_app.dart';
import 'vanya_decision.dart';
import 'vanya_task.dart';

/// A completed intervention, kept for two purposes: local history (so a
/// later Statistics feature has clean data to read, per the product brief)
/// and recent context fed back into future `InterventionContext`s, so
/// reasoning can eventually notice patterns like "asked for TikTok three
/// times during homework today." Deliberately a flat snapshot — it stores
/// the task's *title* at the time, not a live reference to a `VanyaTask`,
/// since that task could be edited or deleted later without invalidating
/// history.
class InterventionHistoryEntry {
  const InterventionHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.packageName,
    required this.appDisplayName,
    this.currentTaskTitle,
    this.userReason,
    required this.decisionType,
    required this.decisionMessage,
    this.temporaryAccessDuration,
  });

  final String id;
  final DateTime timestamp;
  final String packageName;
  final String appDisplayName;
  final String? currentTaskTitle;
  final String? userReason;
  final VanyaDecisionType decisionType;
  final String decisionMessage;
  final Duration? temporaryAccessDuration;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'packageName': packageName,
        'appDisplayName': appDisplayName,
        'currentTaskTitle': currentTaskTitle,
        'userReason': userReason,
        'decisionType': decisionType.name,
        'decisionMessage': decisionMessage,
        'temporaryAccessMinutes': temporaryAccessDuration?.inMinutes,
      };

  factory InterventionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final minutes = json['temporaryAccessMinutes'] as int?;
    return InterventionHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      packageName: json['packageName'] as String,
      appDisplayName: json['appDisplayName'] as String,
      currentTaskTitle: json['currentTaskTitle'] as String?,
      userReason: json['userReason'] as String?,
      decisionType: VanyaDecisionType.values.byName(json['decisionType'] as String),
      decisionMessage: json['decisionMessage'] as String,
      temporaryAccessDuration: minutes != null ? Duration(minutes: minutes) : null,
    );
  }
}

/// Everything Vanya's reasoning needs to decide what to do about a
/// protected app being opened. Built by the intervention flow, handed to
/// `VanyaReasoningService.evaluate` — the service should need nothing else
/// from the rest of the app.
class InterventionContext {
  const InterventionContext({
    required this.protectedApp,
    required this.currentTime,
    this.currentTask,
    this.nextTask,
    this.userPreferences = const [],
    this.userReason,
    this.recentInterventions = const [],
  });

  final ProtectedApp protectedApp;
  final DateTime currentTime;
  final VanyaTask? currentTask;
  final VanyaTask? nextTask;

  /// The user's stated goals/intentions from onboarding (e.g. "Focus",
  /// "Sleep") — not wired to the real onboarding answers yet, just present
  /// structurally so reasoning can eventually read them.
  final List<String> userPreferences;

  /// What the user typed when asked why they want in — filled in partway
  /// through the flow, so this starts null and the flow rebuilds the
  /// context once the user submits a reason.
  final String? userReason;

  /// A limited slice of recent history (not the whole local database) —
  /// see `InterventionHistoryService.recent`.
  final List<InterventionHistoryEntry> recentInterventions;

  InterventionContext copyWith({String? userReason}) {
    return InterventionContext(
      protectedApp: protectedApp,
      currentTime: currentTime,
      currentTask: currentTask,
      nextTask: nextTask,
      userPreferences: userPreferences,
      userReason: userReason ?? this.userReason,
      recentInterventions: recentInterventions,
    );
  }
}
