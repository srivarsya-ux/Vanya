import 'dart:async';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'oneir_widget_messages.dart';

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
  ///
  /// Also decides and pushes Vanya's occasional contextual line (see
  /// OneirWidgetMessages.pick()) -- a morning greeting, "that's one
  /// down," or nothing at all most of the time. Reads back the previous
  /// done-count and last-greeted-date it saved on the prior call so it
  /// can tell "a task was just completed" apart from "this is just a
  /// routine redraw with nothing new."
  static Future<void> updateTodaysFocus(List<({String label, bool done})> tasks) async {
    final capped = tasks.take(3).toList();
    final payload = capped.map((t) => {'label': t.label, 'done': t.done}).toList();
    final doneCount = capped.where((t) => t.done).length;

    final previousDoneCount = await HomeWidget.getWidgetData<int>('todays_focus_done_count', defaultValue: 0) ?? 0;
    final lastGreetedDate = await HomeWidget.getWidgetData<String>('todays_focus_last_greeted_date');

    final now = DateTime.now();
    final message = OneirWidgetMessages.pick(
      doneCount: doneCount,
      totalCount: capped.length,
      previousDoneCount: previousDoneCount,
      lastGreetedDate: lastGreetedDate,
      now: now,
    );

    await HomeWidget.saveWidgetData<String>('todays_focus_tasks', jsonEncode(payload));
    await HomeWidget.saveWidgetData<String>('todays_focus_message', message ?? '');
    await HomeWidget.saveWidgetData<int>('todays_focus_done_count', doneCount);
    if (message == 'Good morning.') {
      await HomeWidget.saveWidgetData<String>('todays_focus_last_greeted_date', OneirWidgetMessages.todayKey(now));
    }
    await HomeWidget.updateWidget(name: _todaysFocusProvider, androidName: _todaysFocusProvider);
  }

  /// Widget 2 -- "Quick Focus": a tappable 25-minute session starter.
  /// [isRunning]/[remainingMinutes] reflect a session already in
  /// progress (if any) so the widget shows a countdown instead of the
  /// static "25 min" prompt while a session is active.
  ///
  /// Also decides Vanya's occasional line under the countdown -- "You're
  /// doing well" once, at the halfway point of a real running session
  /// (never repeated within that same session, tracked via
  /// quick_focus_encouraged), and "Nice work." when [completed] marks a
  /// session that actually finished rather than one that was merely
  /// paused or manually reset. Silent the rest of the time, same
  /// restraint rule as every other widget message.
  static Future<void> updateQuickFocus({
    bool isRunning = false,
    int remainingMinutes = 25,
    int totalMinutes = 25,
    bool completed = false,
  }) async {
    String? message;

    if (completed) {
      message = 'Nice work.';
      await HomeWidget.saveWidgetData<bool>('quick_focus_encouraged', false);
    } else if (remainingMinutes >= totalMinutes) {
      // A fresh or reset timer -- clear the per-session flag so the next
      // real session can earn its own encouragement again.
      await HomeWidget.saveWidgetData<bool>('quick_focus_encouraged', false);
    } else if (isRunning) {
      final alreadyEncouraged = await HomeWidget.getWidgetData<bool>('quick_focus_encouraged', defaultValue: false) ?? false;
      final halfway = (totalMinutes / 2).ceil();
      if (!alreadyEncouraged && remainingMinutes <= halfway) {
        message = "You're doing well.";
        await HomeWidget.saveWidgetData<bool>('quick_focus_encouraged', true);
      }
    }

    await HomeWidget.saveWidgetData<bool>('quick_focus_running', isRunning);
    await HomeWidget.saveWidgetData<int>('quick_focus_remaining', remainingMinutes);
    await HomeWidget.saveWidgetData<String>('quick_focus_message', message ?? '');
    await HomeWidget.updateWidget(name: _quickFocusProvider, androidName: _quickFocusProvider);
  }

  /// Widget 3 -- "Vanya Daily Check-in": a standing prompt + an add-task
  /// shortcut. The prompt itself now evolves natively -- see
  /// VanyaCheckInWidgetProvider.promptFor(), which reads the same
  /// todays_focus_tasks data [updateTodaysFocus] already pushes for
  /// Widget 1. This method stays as the plain redraw trigger it always
  /// was; no new data needed to flow through it for the prompt to change.
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
