import '../models/intervention_context.dart';
import '../models/protected_app.dart';
import '../models/temporary_access_grant.dart';
import 'intervention_flow_service.dart';
import 'protected_app_service.dart';
import 'temporary_access_service.dart';

/// The seam the future Android enforcement layer (Accessibility Service,
/// Usage Access, an overlay detecting a protected app opening) will call
/// into instead of talking to the intervention system's internals
/// directly. Nothing in here touches an Android API yet — it's a clean
/// abstraction over the same [ProtectedAppService]/[TemporaryAccessService]/
/// [InterventionFlowService] the UI already uses, so wiring in real
/// detection later means implementing a caller for this interface, not
/// rewriting the intervention system.
class AppAccessController {
  AppAccessController({
    required this.protectedAppService,
    required this.temporaryAccessService,
    required this.flow,
  });

  final ProtectedAppService protectedAppService;
  final TemporaryAccessService temporaryAccessService;
  final InterventionFlowService flow;

  bool isAppProtected(String packageName) =>
      protectedAppService.isProtected(packageName);

  bool hasTemporaryAccess(String packageName) =>
      temporaryAccessService.hasActiveAccess(packageName);

  /// What enforcement would call the moment a protected app opens.
  /// Returns null when access is already allowed (an active temporary
  /// grant) — no intervention needed. Otherwise returns the
  /// [InterventionContext] the UI should show an intervention for.
  InterventionContext? requestAccess(ProtectedApp app) => flow.prepareIntervention(app);

  Future<TemporaryAccessGrant> grantTemporaryAccess({
    required String packageName,
    required Duration duration,
    required String reason,
    required String source,
  }) {
    return temporaryAccessService.createGrant(
      packageName: packageName,
      duration: duration,
      reason: reason,
      source: source,
    );
  }

  Future<void> revokeAccess(String grantId) => temporaryAccessService.revoke(grantId);
}
