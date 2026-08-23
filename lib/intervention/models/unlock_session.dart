/// A single approved-access window for a protected app -- what
/// UnlockScheduler tracks and what fires the re-lock intervention when it
/// expires.
class UnlockSession {
  final String packageName;
  final DateTime startTime;
  final Duration allowedDuration;
  final String reason;

  const UnlockSession({
    required this.packageName,
    required this.startTime,
    required this.allowedDuration,
    required this.reason,
  });

  DateTime get expiresAt => startTime.add(allowedDuration);

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => remaining == Duration.zero;

  UnlockSession extendedBy(Duration extra) => UnlockSession(
        packageName: packageName,
        startTime: startTime,
        allowedDuration: allowedDuration + extra,
        reason: reason,
      );

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'startTime': startTime.toIso8601String(),
        'allowedMinutes': allowedDuration.inMinutes,
        'reason': reason,
      };

  factory UnlockSession.fromJson(Map<String, dynamic> json) => UnlockSession(
        packageName: json['packageName'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        allowedDuration: Duration(minutes: json['allowedMinutes'] as int),
        reason: json['reason'] as String,
      );
}
