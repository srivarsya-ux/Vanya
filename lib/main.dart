import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screens.dart';
import 'screens/how_app_habits_work_screen.dart';
import 'screens/name_entry_screen.dart';
import 'screens/why_here_screen.dart';
import 'screens/protected_apps_screen.dart';
// The old scripted InteractiveDemoScreen (three fixed lines, one canned
// question) was removed from the onboarding flow per explicit request --
// that file/class still exists (unused), same pattern as other superseded
// screens elsewhere in this project, not deleted outright. It's now
// replaced in the flow below by AiInterventionDemoScreen, which opens the
// real AI-backed conversation screen instead of a script.
import 'screens/ai_intervention_demo_screen.dart';
import 'screens/co_keeper_screens.dart';
import 'screens/enable_protection_screen.dart';
import 'screens/usage_access_screen.dart';
import 'screens/accessibility_permission_screen.dart';
import 'screens/permission_screens.dart';
import 'screens/widget_setup_screen.dart';
import 'screens/why_vanya_works_screen.dart';
import 'screens/almost_there_and_ready_screens.dart';
import 'screens/widgets_and_home_screens.dart';
import 'native/oneir_protection.dart';
import 'backend/co_keeper_backend.dart';
// Registers the `interruptionMain` entrypoint (launched natively by
// InterruptionActivity) -- unused directly here, but importing it is what
// keeps it included in the compiled app at all.
// ignore: unused_import
import 'interruption/interruption_main.dart';
// Registers the new AI intervention entrypoint (see lib/intervention/) --
// unused directly here, importing it is what keeps it compiled in.
// ignore: unused_import
import 'intervention/smart_intervention_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase isn't set up yet in every environment this runs in (no
  // firebase_options.dart until `flutterfire configure` has been run --
  // see android_native_files/SETUP.md). Rather than crashing the whole app
  // on startup whenever that's missing, catch it here: the Co-Keeper
  // backend features just won't work until it's configured, but everything
  // else (the full UI flow) still will.
  try {
    await Firebase.initializeApp();
    await CoKeeperBackend.registerDeviceForPush();
  } catch (e) {
    debugPrint('Firebase not configured yet -- Co-Keeper backend features are disabled: $e');
  }
  runApp(const ProviderScope(child: OneirApp()));
}

class OneirApp extends StatelessWidget {
  const OneirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oneir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'PlusJakartaSans', useMaterial3: true),
      home: const OneirEntryGate(),
    );
  }
}

/// Checks persisted state on startup so a returning user goes straight to
/// Home with their saved name instead of sitting through onboarding again
/// every time they open the app.
class OneirEntryGate extends StatelessWidget {
  const OneirEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupState>(
      future: _loadStartupState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final state = snapshot.data!;
        return state.onboarded ? HomeScreen(name: state.name) : const OneirFlow();
      },
    );
  }

  Future<_StartupState> _loadStartupState() async {
    final onboarded = await OneirProtection.isOnboardingComplete();
    final name = onboarded ? await OneirProtection.loadUserName() : '';
    return _StartupState(onboarded: onboarded, name: name);
  }
}

class _StartupState {
  final bool onboarded;
  final String name;
  const _StartupState({required this.onboarded, required this.name});
}

/// Drives the whole onboarding -> home flow with a single PageView so every
/// screen gets the same slide transition. Follows the 12-step story flow
/// (Meet Vanya -> Understand You -> Protect You -> Team & Trust -> Secure &
/// Enable -> You're Ready):
/// Splash -> Welcome -> I'll Help You -> What's Your Name -> Why Are You
/// Here -> Choose Apps -> Interruption Demo -> Who's Your Team -> Invite
/// Co-Keeper -> Enable Protection -> Accessibility -> Display Over Apps ->
/// Notifications -> Widgets -> Almost There -> You're Ready -> Home
class OneirFlow extends StatefulWidget {
  const OneirFlow({super.key});

  @override
  State<OneirFlow> createState() => _OneirFlowState();
}

class _OneirFlowState extends State<OneirFlow> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _index = 0;

  // Set from the real screens list length at the top of build() every
  // time, rather than a separate hardcoded number -- a hardcoded
  // `_pageCount` here is exactly what caused a real bug: it went stale
  // (17) after the screens list below was edited to 18 entries, silently
  // blocking navigation past the Ready/Celebration screen since the guard
  // in _goNext() fired one page early. Deriving it from the actual list
  // means it can never drift out of sync with reality again.
  int _totalPages = 0;

  void _goNext() {
    if (_index >= _totalPages - 1) return;
    _pageController.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  void _goBack() {
    if (_index <= 0) return;
    _pageController.previousPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  void _skipCoKeeper() {
    // "Maybe Later" jumps straight past the invite flow to the Enable
    // Protection overview, skipping the Co-Keeper-specific steps only.
    // Index 9 = EnableProtectionScreen in the current screens list below
    // (0 Splash, 1 Hello, 2 HowAppHabitsWork, 3 NameEntry, 4 WhyHere,
    // 5 ProtectedApps, 6 AiInterventionDemo, 7 CoKeeperIntro,
    // 8 CoKeeperInvite, 9 EnableProtection) -- bumped by one from 8 when
    // AiInterventionDemoScreen was inserted after ProtectedApps. There's
    // no way to derive this purely dynamically since it's a *specific*
    // target screen, not just a count -- if the list order above changes
    // again, this needs updating to match (see the stale-index bug this
    // already caused once, noted on _totalPages above).
    _pageController.animateToPage(9, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      SplashScreen(onNext: _goNext),
      HelloScreen(onNext: _goNext, onBack: _goBack), // Step 01: Hello
      HowAppHabitsWorkScreen(onNext: _goNext, onBack: _goBack), // Step 02: How App Habits Work
      NameEntryScreen(onNext: _goNext, nameController: _nameController, onBack: _goBack),
      WhyHereScreen(onNext: _goNext, onBack: _goBack), // Step 03: Why Are You Here
      ProtectedAppsScreen(onNext: _goNext, onBack: _goBack), // Step 04: Choose Protected Apps
      AiInterventionDemoScreen(onNext: _goNext, onBack: _goBack), // Step 04a: Talk to the real Vanya
      CoKeeperIntroScreen(onNext: _goNext, onSkip: _skipCoKeeper, onBack: _goBack), // Step 05: Meet the Co-Keeper
      CoKeeperInviteScreen(onNext: _goNext, onBack: _goBack), // Step 06: Invite Co-Keeper
      EnableProtectionScreen(onNext: _goNext, onBack: _goBack), // Step 07: Permissions overview
      UsageAccessScreen(onNext: _goNext, onBack: _goBack), // Step 07a: Usage Access
      NotificationsPermissionScreen(onNext: _goNext, onBack: _goBack),
      DisplayOverAppsScreen(onNext: _goNext, onBack: _goBack),
      AccessibilityPermissionScreen(onNext: _goNext, onBack: _goBack),
      WidgetSetupScreen(onNext: _goNext, onBack: _goBack), // Step 08: Widget Setup
      WhyVanyaWorksScreen(onNext: _goNext, onBack: _goBack), // Step 09: Why Vanya Works
      AlmostThereScreen(onNext: _goNext, onBack: _goBack),
      ReadyScreen(onNext: _goNext, onBack: _goBack), // Celebration
      AnimatedBuilder(
        animation: _nameController,
        builder: (context, _) => HomeScreen(name: _nameController.text.trim()),
      ),
    ];

    _totalPages = screens.length;

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // navigation is driven by in-screen actions, not swipes
      onPageChanged: (i) => setState(() => _index = i),
      children: [
        for (var i = 0; i < screens.length; i++)
          _WarmPageTransition(controller: _pageController, index: i, child: screens[i]),
      ],
    );
  }
}

/// Softens the plain slide between onboarding screens into something that
/// feels less like flipping a page and more like each screen gently settles
/// into place -- a light fade-in plus a small scale-up as a page becomes
/// current, rather than a flat hard-edged cut. Purely cosmetic on top of
/// PageView's own scroll animation, so it costs nothing functionally.
class _WarmPageTransition extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget child;

  const _WarmPageTransition({required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double page;
        try {
          page = controller.page ?? controller.initialPage.toDouble();
        } catch (_) {
          page = controller.initialPage.toDouble();
        }
        final distance = (page - index).clamp(-1.0, 1.0).abs().toDouble();
        final opacity = (1 - distance).clamp(0.0, 1.0).toDouble();
        final scale = 0.97 + (0.03 * (1 - distance));
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
