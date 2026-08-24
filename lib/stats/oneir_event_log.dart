import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// The real events Statistics is actually able to report on honestly.
/// Deliberately NOT "every possible metric" -- each value here is
/// something the app can measure for real from its own behavior, not
/// something that would need full Android usage-stats mining to compute
/// truthfully. See StatisticsScreen's doc comment for which brief-requested
/// numbers this does and doesn't cover yet.
enum OneirEventType {
  /// A protected-app intervention ended in `redirect` -- Vanya
  /// successfully helped the user not open the app. This is the real
  /// basis for "interruptions avoided."
  interventionRedirect,

  /// A protected-app intervention ended in `allow` -- an unlock session
  /// was granted. Counted alongside redirects for "most protected app"
  /// (either outcome means that app is the one triggering check-ins).
  interventionAllow,

  /// A real focus session (see FocusTimeScreen) ran to completion.
  focusSessionCompleted,
}

/// One real, timestamped thing that happened -- never sample/invented
/// data. See OneirEventLog for where these are read back.
class OneirEvent {
  final OneirEventType type;
  final DateTime timestamp;
  final String? appLabel;
  final String? packageName;
  final int? minutes;

  const OneirEvent({
    required this.type,
    required this.timestamp,
    this.appLabel,
    this.packageName,
    this.minutes,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestampMs': timestamp.millisecondsSinceEpoch,
        if (appLabel != null) 'appLabel': appLabel,
        if (packageName != null) 'packageName': packageName,
        if (minutes != null) 'minutes': minutes,
      };

  /// Returns null (never throws) for a row that doesn't parse -- one
  /// corrupt entry should never take down the whole log.
  static OneirEvent? fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    if (rawType == null) return null;
    OneirEventType? type;
    for (final t in OneirEventType.values) {
      if (t.name == rawType) {
        type = t;
        break;
      }
    }
    if (type == null) return null;

    final ms = json['timestampMs'] as int?;
    if (ms == null) return null;

    return OneirEvent(
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
      appLabel: json['appLabel'] as String?,
      packageName: json['packageName'] as String?,
      minutes: (json['minutes'] as num?)?.toInt(),
    );
  }
}

/// A real, persisted event log -- the thing StatisticsScreen's own code
/// comment said didn't exist yet. Every call site that logs something
/// real (InterventionController on a decision, FocusTimeScreen on a
/// finished session) is the ONLY source of truth for these numbers;
/// nothing in this file or in StatisticsScreen invents a number that
/// wasn't actually logged.
class OneirEventLog {
  OneirEventLog._();

  static const _key = 'oneir_event_log_v1';

  /// Caps how many events are kept on disk so this never grows unbounded
  /// over months of real use -- generous enough to comfortably cover many
  /// weeks of normal use, since everything this log currently feeds
  /// (StatisticsScreen) only ever looks at the last one or two weeks.
  static const _maxEvents = 500;

  static Future<void> log(OneirEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(event.toJson()));
    final trimmed = raw.length > _maxEvents ? raw.sublist(raw.length - _maxEvents) : raw;
    await prefs.setStringList(_key, trimmed);
  }

  static Future<List<OneirEvent>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final events = <OneirEvent>[];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          final event = OneirEvent.fromJson(decoded);
          if (event != null) events.add(event);
        }
      } catch (_) {
        // Skip one corrupt row rather than losing the whole log.
      }
    }
    return events;
  }

  static Future<List<OneirEvent>> loadSince(DateTime since) async {
    final all = await loadAll();
    return all.where((e) => e.timestamp.isAfter(since)).toList();
  }
}
