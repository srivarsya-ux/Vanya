/// A time-boxed exception letting a protected app open without an
/// intervention. Application-level bookkeeping only — this does not bypass
/// any real Android restriction (there isn't one yet); it's the record
/// `TemporaryAccessService` and the future enforcement layer will check
/// against.
class TemporaryAccessGrant {
  const TemporaryAccessGrant({
    required this.id,
    required this.packageName,
    required this.grantedAt,
    required this.expiresAt,
    required this.reason,
    required this.source,
    this.revokedAt,
  });

  final String id;
  final String packageName;
  final DateTime grantedAt;
  final DateTime expiresAt;

  /// Why access was granted — e.g. the user's stated reason, surfaced back
  /// through `VanyaDecision.message`.
  final String reason;

  /// Where the decision came from — e.g. `'mock_reasoning'`,
  /// `'actual_reasoning'`, `'manual_override'`. A free string rather than
  /// an enum so new decision sources (a future real AI service, a manual
  /// debug override) don't require touching this model.
  final String source;

  final DateTime? revokedAt;

  bool isActiveAt(DateTime moment) =>
      revokedAt == null && moment.isBefore(expiresAt);

  bool get isActive => isActiveAt(DateTime.now());

  TemporaryAccessGrant revoke() => TemporaryAccessGrant(
        id: id,
        packageName: packageName,
        grantedAt: grantedAt,
        expiresAt: expiresAt,
        reason: reason,
        source: source,
        revokedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'grantedAt': grantedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'reason': reason,
        'source': source,
        'revokedAt': revokedAt?.toIso8601String(),
      };

  factory TemporaryAccessGrant.fromJson(Map<String, dynamic> json) {
    return TemporaryAccessGrant(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      reason: json['reason'] as String,
      source: json['source'] as String,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
    );
  }
}
