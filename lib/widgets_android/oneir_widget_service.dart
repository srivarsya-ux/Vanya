import 'dart:async';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';

/// The two distinct "open the app and go somewhere specific" actions the
/// widgets can trigger. Widget 1 (Today's Focus) has no distinct action --
/// tapping it just opens the app normally.
enum OneirWidgetLaunch {
  /// Widget 2 (Quick Focus) was tapped -- land on a real focus session.
  focusSession,

  /// Widget 3 (Vanya Daily Check-in)'s "+ Add task" button was tapped --
  /// land on Tasks with the add-task field ready to type into.
  quickAddTask,
}

/// Pushes real app state to the three native Android App Widgets, and
/// receives taps from them. This is the ONLY place Dart code talks to
/// the widget system -- callers (Home screen, focus session start/stop,
/// task toggling) call these methods; nothing widget-specific leaks into
/// screen code.
///
/// Uses `home_widget`, the standard Flutter<->native-widget bridge --
/// writes go into Android's widget-scoped SharedPreferences (a different
/// store than the app's own shared_preferences), which the three
/// AppWidgetProvider classes in android_native_files/widgets/kotlin/ read
/// directly. See android_native_files/SETUP.md for the manual native
/// wiring step every native addition in this project has needed.
class OneirWidgetService {
  OneirWidgetService._();

  static const _todaysFocusProvider = 'TodaysFocusWidgetProvider';
  static const _quickFocusProvider = 'QuickFocusWidgetProvider';
  static const _checkInProvider = 'VanyaCheckInWidgetProvider';

  /// Widget 1 -- "Today's Focus": up to 3 tasks with done state. Call
  /// whenever the Home screen's task list changes (add/complete/remove).
  static Future<void> updateTodaysFocus(List<({String label, bool done})> tasks) async {
    final payload = tasks.take(3).map((t) => {'label': t.label, 'done': t.done}).toList();
    await HomeWidget.saveWidgetData<String>('todays_focus_tasks', jsonEncode(payload));
    await HomeWidget.updateWidget(name: _todaysFocusProvider, androidName: _todaysFocusProvider);
  }

  /// Widget 2 -- "Quick Focus": a tappable 25-minute session starter.
  /// [isRunning]/[remainingMinutes] reflect a session already in
  /// progress (if any) so the widget shows a countdown instead of the
  /// static "25 min" prompt while a session is active.
  static Future<void> updateQuickFocus({bool isRunning = false, int remainingMinutes = 25}) async {
    await HomeWidget.saveWidgetData<bool>('quick_focus_running', isRunning);
    await HomeWidget.saveWidgetData<int>('quick_focus_remaining', remainingMinutes);
    await HomeWidget.updateWidget(name: _quickFocusProvider, androidName: _quickFocusProvider);
  }

  /// Widget 3 -- "Vanya Daily Check-in": a standing prompt + an add-task
  /// shortcut. The prompt itself is static UI copy (not per-user data),
  /// so there's nothing to push here beyond triggering a redraw after
  /// install/update -- kept as a method for symmetry with the other two
  /// and as the natural place to add a real rotating prompt later.
  static Future<void> refreshCheckIn() async {
    await HomeWidget.updateWidget(name: _checkInProvider, androidName: _checkInProvider);
  }

  /// Decodes the Uri the two action-carrying widgets (Quick Focus, Vanya
  /// Daily Check-in) launch the app with -- see QuickFocusWidgetProvider
  /// and VanyaCheckInWidgetProvider, which build their PendingIntent via
  /// home_widget's own `HomeWidgetLaunchIntent.getActivity(context,
  /// MainActivity::class.java, uri)`. Returns null for a plain "just
  /// open the app" launch (Widget 1, or the app opened normally).
  static OneirWidgetLaunch? _decodeLaunch(Uri? uri) {
    switch (uri?.host) {
      case 'focus':
        return OneirWidgetLaunch.focusSession;
      case 'quick_add_task':
        return OneirWidgetLaunch.quickAddTask;
      default:
        return null;
    }
  }

  /// Cold-start case: call once at startup (e.g. HomeScreen.initState) to
  /// check whether *this* launch of the app was triggered by tapping a
  /// widget action, so the very first frame can route straight there
  /// instead of landing on Home first.
  static Future<OneirWidgetLaunch?> consumeInitialLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    return _decodeLaunch(uri);
  }

  /// Warm case: the app was already running when a widget was tapped.
  /// Call once (alongside [consumeInitialLaunch], e.g. in
  /// HomeScreen.initState) and route on whatever recognized action comes
  /// through; unrecognized/null taps (Widget 1's plain open) are ignored
  /// here rather than passed to the callback. Returns the subscription so
  /// the caller can cancel it in dispose().
  ///
  /// NOTE: this is deliberately *not* `HomeWidget.registerInteractivityCallback`
  /// (the renamed `registerBackgroundCallback`, home_widget >=0.4.0) --
  /// that API runs Dart in a background isolate to update widget data
  /// *without* opening the app, which isn't what either widget needs here
  /// since both are meant to open the app and land somewhere. An earlier
  /// version of this doc comment pointed at that API by mistake; leaving
  /// this note so the correction doesn't get silently lost.
  static StreamSubscription<Uri?> registerLaunchListener(void Function(OneirWidgetLaunch action) onLaunch) {
    return HomeWidget.widgetClicked.listen((uri) {
      final action = _decodeLaunch(uri);
      if (action != null) onLaunch(action);
    });
  }
}
