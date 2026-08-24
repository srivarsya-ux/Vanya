/// Decides the small contextual line shown under the task list on the
/// Today's Focus home-screen widget (see android_native_files/widgets/
/// kotlin/TodaysFocusWidgetProvider.kt + widget_todays_focus.xml's
/// todays_focus_message row).
///
/// Per the brief: this widget is meant to occasionally say something --
/// "Good morning," "You're doing well," "That's one down" -- but NOT on
/// every single refresh. "And sometimes: nothing. That restraint
/// matters." So [pick] only returns a message on specific, meaningful
/// transitions (a task was just finished, or this is the first look of
/// the day) and returns null the rest of the time -- callers must treat
/// null as "hide the message row entirely," not "show something generic."
class OneirWidgetMessages {
  OneirWidgetMessages._();

  /// [previousDoneCount] lets the caller detect "a task was just
  /// completed this refresh" (doneCount > previousDoneCount) versus a
  /// routine redraw with nothing new to say.
  ///
  /// [lastGreetedDate] is whatever was previously saved by
  /// [todayKey] -- passing the same value back after a morning greeting
  /// stops it repeating on every refresh for the rest of the morning.
  static String? pick({
    required int doneCount,
    required int totalCount,
    required int previousDoneCount,
    required String? lastGreetedDate,
    required DateTime now,
  }) {
    // A task was just finished this refresh -- always worth marking,
    // regardless of time of day.
    if (totalCount > 0 && doneCount > previousDoneCount) {
      return doneCount >= totalCount ? "That's everything today." : "That's one down.";
    }

    // First look of the day, nothing touched yet, and today's morning
    // greeting hasn't already been shown -- once per day, not every
    // refresh between 4am and 11am.
    if (doneCount == 0 && now.hour >= 4 && now.hour < 11 && lastGreetedDate != todayKey(now)) {
      return 'Good morning.';
    }

    // Everything else -- a plain refresh with nothing new to report --
    // stays silent on purpose.
    return null;
  }

  /// A stable per-day key ("2026-08-24") for tracking whether today's
  /// morning greeting has already been shown, so [pick] doesn't repeat it
  /// on every widget refresh within the same morning.
  static String todayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
