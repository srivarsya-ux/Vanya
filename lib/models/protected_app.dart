/// An app the user has chosen for Vanya to help with. Data/service layer
/// only — this deliberately does not know anything about how protection is
/// actually enforced on Android (Accessibility Service, overlay, etc.);
/// that's separate, later work.
class ProtectedApp {
  const ProtectedApp({
    required this.packageName,
    required this.displayName,
    this.isProtected = true,
  });

  final String packageName;
  final String displayName;
  final bool isProtected;

  ProtectedApp copyWith({bool? isProtected}) {
    return ProtectedApp(
      packageName: packageName,
      displayName: displayName,
      isProtected: isProtected ?? this.isProtected,
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'displayName': displayName,
        'isProtected': isProtected,
      };

  factory ProtectedApp.fromJson(Map<String, dynamic> json) {
    return ProtectedApp(
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
      isProtected: json['isProtected'] as bool? ?? true,
    );
  }
}
