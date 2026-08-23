import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/oneir_theme.dart';
import 'widgets/intervention_conversation_screen.dart';
import 'services/unlock_scheduler.dart';

/// A second, separate entrypoint alongside the existing `interruptionMain`
/// (lib/interruption/interruption_main.dart) -- that one still owns the
/// graduated check-in/intention/Co-Keeper-gate flow already built and
/// approved earlier. This is the new AI conversation-driven intervention
/// described in the brief, kept as its own entrypoint rather than
/// replacing the existing one, so nothing already shipped gets torn out.
///
/// Which one actually runs when a protected app opens is a native-side
/// routing decision (e.g. a "Smart Mode" toggle in Settings) -- see
/// android_native_files/SETUP.md for how to wire that choice into
/// InterruptionActivity.
@pragma('vm:entry-point')
void smartInterventionMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnlockScheduler.instance.resumePersistedTimers();

  final packageName = args.isNotEmpty ? args[0] : '';
  final appLabel = args.length > 1 ? args[1] : packageName;
  final isReLockFollowUp = args.length > 2 && args[2] == 'relock';

  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'PlusJakartaSans', useMaterial3: true, scaffoldBackgroundColor: OneirColors.background),
        home: InterventionConversationScreen(
          appLabel: appLabel,
          packageName: packageName,
          isReLockFollowUp: isReLockFollowUp,
          onDismiss: () {
            // Real behavior on Android: moveTaskToBack + finish, same
            // pattern as InterruptionActivity's existing "returnHome"
            // channel method -- needs the same platform-channel wiring
            // added to this entrypoint's own Activity once one exists
            // (see SETUP.md).
          },
          onLaunchApp: () {
            // Real behavior on Android: finish() this Activity so the
            // protected app underneath (already opened by the user) is
            // revealed -- same pattern as the existing
            // "returnToOpenedApp" channel method.
          },
        ),
      ),
    ),
  );
}
