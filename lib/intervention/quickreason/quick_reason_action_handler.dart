import '../../native/oneir_protection.dart';
import '../../backend/co_keeper_backend.dart';
import 'quick_reason.dart';

/// Executes an [InterventionAction] for real -- every action here does
/// something genuine (native return-home/return-to-app channel calls, a
/// real snooze write, a real Co-Keeper request), never a fake success.
class QuickReasonActionHandler {
  QuickReasonActionHandler._();

  static Future<void> execute(InterventionAction action, {required String packageName, required String appLabel}) async {
    switch (action) {
      case InterventionAction.backToTask:
      case InterventionAction.returnToPrevious:
        await OneirProtection.returnHome();
        break;

      case InterventionAction.startShortBreak:
        await OneirProtection.startShortBreakSnooze(packageName);
        await OneirProtection.returnHome();
        break;

      case InterventionAction.askCoKeeper:
        try {
          await CoKeeperBackend.createPendingPairing(coKeeperName: appLabel);
        } catch (_) {
          // Firebase not configured / offline -- the request UI already
          // surfaces this state elsewhere; this action just shouldn't
          // crash the intervention flow if it fails.
        }
        break;

      case InterventionAction.continueToApp:
        await OneirProtection.returnToOpenedApp();
        break;
    }
  }
}
