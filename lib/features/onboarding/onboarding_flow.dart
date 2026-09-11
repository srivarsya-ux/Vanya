import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';

import '../../design_system/vanya_animation.dart';
import '../../design_system/vanya_colors.dart';
import '../../native/vanya_permissions.dart';
import 'onboarding_state.dart';
import 'screens/onboarding_arrival_screen.dart';
import 'screens/onboarding_intention_screen.dart';
import 'screens/onboarding_meet_vanya_screen.dart';
import 'screens/onboarding_moments_screen.dart';
import 'screens/onboarding_name_screen.dart';
import 'screens/onboarding_permission_intro_screen.dart';
import 'screens/onboarding_permission_screen.dart';
import 'screens/onboarding_promise_screen.dart';
import 'screens/onboarding_protected_apps_screen.dart';
import 'screens/onboarding_ready_screen.dart';
import 'widgets/onboarding_progress_indicator.dart';

/// Loads [OnboardingState] from disk, then hosts every onboarding screen in
/// a single [PageView] wrapped in a [ChangeNotifierProvider] — so state
/// (name, goals, moments, target, protected apps, permission progress)
/// survives leaving and returning to onboarding, and every screen reads/
/// writes it directly instead of threading callbacks through this widget.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

/// Screens from [_nameStepIndex] onward show the progress dots; Arrival and
/// Meet Vanya stay pure introduction, no step-counting.
const int _nameStepIndex = 2;
const int _totalSteps = 12; // pages [_nameStepIndex, _lastPageIndex]
const int _lastPageIndex = _nameStepIndex + _totalSteps - 1;

class _OnboardingFlowState extends State<OnboardingFlow> {
  OnboardingState? _state;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    OnboardingState.load().then((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        _pageController = PageController(
          initialPage: state.currentStep.clamp(0, _lastPageIndex),
        );
      });
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final controller = _pageController;
    if (state == null || controller == null) {
      final colors = context.vanyaColors;
      return ColoredBox(
        color: colors.background,
        child: Center(child: CircularProgressIndicator(color: colors.accent)),
      );
    }

    return ChangeNotifierProvider.value(
      value: state,
      child: _OnboardingPages(controller: controller),
    );
  }
}

class _OnboardingPages extends StatefulWidget {
  const _OnboardingPages({required this.controller});

  final PageController controller;

  @override
  State<_OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<_OnboardingPages> {
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.controller.initialPage;
  }

  /// Awaits [OnboardingState.flush] before animating — page navigation is
  /// exactly the moment a user might background or kill the app right
  /// after, so every state change up to and including this step change
  /// needs to be durably on disk before the transition completes, not just
  /// queued (see the doc on `OnboardingState._commit`).
  Future<void> _goToPage(int index) async {
    final state = context.read<OnboardingState>();
    state.setCurrentStep(index);
    await state.flush();
    if (!mounted) return;
    await widget.controller.animateToPage(
      index,
      duration: VanyaAnimation.unfoldDuration,
      curve: VanyaAnimation.unfoldCurve,
    );
  }

  void _goNext() => _goToPage(_pageIndex + 1);
  void _goBack() => _goToPage(_pageIndex - 1);

  /// Each screen's progress dots reflect *that screen's own fixed position*
  /// in the flow, not whichever page happens to be visible right now —
  /// [PageView] builds every child eagerly (its `children:` isn't a lazy
  /// builder), so a version of this keyed off the currently-visible page
  /// index would compute the same (wrong) value for every screen in one
  /// build pass.
  Widget _progressFor(int pageIndex) {
    return OnboardingProgressIndicator(
      currentStep: pageIndex - _nameStepIndex,
      totalSteps: _totalSteps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();

    return Scaffold(
      body: PageView(
        controller: widget.controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _pageIndex = index),
        children: [
          OnboardingArrivalScreen(onContinue: _goNext),
          OnboardingMeetVanyaScreen(onContinue: _goNext, onBack: _goBack),
          OnboardingNameScreen(
            initialName: state.userName,
            onContinue: (name) {
              state.setUserName(name);
              _goNext();
            },
            onBack: _goBack,
            progressIndicator: _progressFor(2),
          ),
          OnboardingIntentionScreen(
            selected: state.intentions,
            onToggle: state.toggleIntention,
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(3),
          ),
          OnboardingMomentsScreen(
            selected: state.moments,
            onToggle: state.toggleMoment,
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(4),
          ),
          OnboardingPromiseScreen(
            selected: state.promiseDuration,
            onSelect: state.setPromiseDuration,
            promiseMade: state.promiseMade,
            onMakePromise: () => state.setPromiseMade(true),
            onContinueAfterPromise: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(5),
          ),
          OnboardingProtectedAppsScreen(
            selected: state.protectedAppPackages,
            onToggle: state.toggleProtectedApp,
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(6),
          ),
          OnboardingPermissionIntroScreen(
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(7),
          ),
          OnboardingPermissionScreen(
            icon: Icons.query_stats_rounded,
            title: 'Usage Access',
            explanation:
                "This lets Vanya see which app is in front right now — "
                "that's how she knows when a protected app opens. Vanya "
                "doesn't see anything inside the app, just its name.",
            actionLabel: 'Turn on in Settings',
            checkGranted: VanyaPermissions.hasUsageAccess,
            requestAction: VanyaPermissions.openUsageAccessSettings,
            onGrantedChanged: (granted) =>
                state.setPermission(usageAccess: granted),
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(8),
          ),
          OnboardingPermissionScreen(
            icon: Icons.layers_rounded,
            title: 'Display Over Other Apps',
            explanation:
                "This lets Vanya's interruption screen actually appear "
                "on top of a protected app when it opens, instead of "
                "just a notification you can swipe away.",
            actionLabel: 'Turn on in Settings',
            checkGranted: VanyaPermissions.canDrawOverlays,
            requestAction: VanyaPermissions.openOverlaySettings,
            onGrantedChanged: (granted) =>
                state.setPermission(overlay: granted),
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(9),
          ),
          OnboardingPermissionScreen(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            explanation:
                "Vanya uses notifications for quiet check-ins and "
                "Co-Keeper updates — never streaks, guilt, or noise.",
            actionLabel: 'Allow Notifications',
            checkGranted: () async =>
                (await ph.Permission.notification.status).isGranted,
            requestAction: () async {
              await ph.Permission.notification.request();
            },
            onGrantedChanged: (granted) =>
                state.setPermission(notifications: granted),
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(10),
          ),
          OnboardingPermissionScreen(
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery Optimization',
            explanation:
                "Android aggressively pauses background apps to save "
                "battery. Exempting Vanya keeps her able to notice "
                "protected apps opening even when she's not on screen.",
            actionLabel: 'Turn on in Settings',
            checkGranted: VanyaPermissions.isIgnoringBatteryOptimizations,
            requestAction: VanyaPermissions.requestIgnoreBatteryOptimizations,
            onGrantedChanged: (granted) =>
                state.setPermission(batteryExemption: granted),
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(11),
          ),
          OnboardingPermissionScreen(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility Service',
            explanation:
                "This is the one that actually lets Vanya notice a "
                "protected app opening in real time. Android requires "
                "it for this kind of gentle interruption — Vanya only "
                "looks at which app is open, nothing you type or see.",
            actionLabel: 'Turn on in Settings',
            checkGranted: VanyaPermissions.isAccessibilityServiceEnabled,
            requestAction: VanyaPermissions.openAccessibilitySettings,
            onGrantedChanged: (granted) =>
                state.setPermission(accessibility: granted),
            onContinue: _goNext,
            onBack: _goBack,
            progressIndicator: _progressFor(12),
          ),
          OnboardingReadyScreen(
            userName: state.userName,
            onBack: _goBack,
            progressIndicator: _progressFor(13),
          ),
        ],
      ),
    );
  }
}
