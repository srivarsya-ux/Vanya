import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';
import '../widgets_android/oneir_widget_service.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'protected_apps_screen.dart';
import 'focus_time_screen.dart';
import 'statistics_screen.dart';

const kWidgetTasks = ['Say hi to Vanya', 'Finish Biology', 'Read 10 pages'];

class WidgetsScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WidgetsScreen({super.key, required this.onNext, this.onBack});

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  final List<bool> _checked = [false, false, false];

  int get _doneCount => _checked.where((c) => c).length;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await OneirProtection.loadTaskState();
    if (!mounted || saved == null) return;
    setState(() {
      for (var i = 0; i < _checked.length && i < saved.length; i++) {
        _checked[i] = saved[i];
      }
    });
  }

  Future<void> _persist() async {
    await OneirProtection.saveTaskState(_checked);
    var firstUnfinished = '';
    for (var i = 0; i < kWidgetTasks.length; i++) {
      if (!_checked[i]) {
        firstUnfinished = kWidgetTasks[i];
        break;
      }
    }
    await OneirProtection.saveCurrentIntention(firstUnfinished);
  }

  Future<void> _handleContinue() async {
    await OneirProtection.setOnboardingComplete();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _doneCount / kWidgetTasks.length;

    return OneirScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(OneirSpace.xxl + 2, OneirSpace.xl, OneirSpace.xxl + 2, OneirSpace.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OneirProgressHeader(progress: 15 / 18, onBack: widget.onBack),
          const SizedBox(height: OneirSpace.xl),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Widget card -- Row+Expanded instead of Stack+Positioned+manually
          // -reserved padding: Flutter's layout engine allocates the space
          // itself here, so this cannot overflow regardless of task label
          // length or card width, unlike guessing a pixel margin by hand.
          OneirCard(
            radius: OneirRadius.xl,
            padding: const EdgeInsets.fromLTRB(OneirSpace.xl, OneirSpace.xl, OneirSpace.lg, OneirSpace.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text("Today's Adventure", style: OneirText.title),
                    const SizedBox(height: OneirSpace.md + 2),
                    for (var i = 0; i < kWidgetTasks.length; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() => _checked[i] = !_checked[i]);
                          _persist();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: OneirSpace.sm),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: _checked[i] ? OneirColors.accent : Colors.transparent,
                                border: _checked[i] ? null : Border.all(color: OneirColors.border, width: 1.5),
                              ),
                              child: _checked[i] ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                            ),
                            const SizedBox(width: OneirSpace.sm + 2),
                            Expanded(
                              child: Text(
                                kWidgetTasks[i],
                                overflow: TextOverflow.ellipsis,
                                style: (_checked[i] ? OneirText.bodyStrong.copyWith(color: OneirColors.textFaint) : OneirText.bodyStrong).copyWith(
                                  decoration: _checked[i] ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: OneirSpace.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 6,
                        backgroundColor: OneirColors.border,
                        valueColor: const AlwaysStoppedAnimation(OneirColors.accent),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: OneirSpace.md),
                const VanyaAnimation(width: 104, height: 104),
              ],
            ),
          ),
          const SizedBox(height: OneirSpace.xxxl - 4),
          Center(
            child: AnimatedScale(
              scale: _doneCount == kWidgetTasks.length ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              // Same fix as the real home screen's cheer/tea switcher just
              // above: the scale bump was already there, but the pose
              // underneath it never actually changed, so finishing every
              // preview task looked identical to not finishing them.
              child: VanyaCharacter(
                expression: _doneCount == kWidgetTasks.length ? VanyaExpression.proud : VanyaExpression.idle,
                width: 280,
                height: 280,
              ),
            ),
          ),
          const SizedBox(height: OneirSpace.xxxl - 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneirSpace.sm),
            child: Text(
              'Your widgets remind you what matters before you even think about scrolling.',
              textAlign: TextAlign.center,
              style: OneirText.heading.copyWith(fontSize: 20.6, fontWeight: FontWeight.w500, color: OneirColors.textMuted, letterSpacing: 0),
            ),
          ),
              ]),
            ),
          ),
          const SizedBox(height: OneirSpace.lg),
          OneirPrimaryButton(label: 'This feels good', onPressed: _handleContinue),
        ]),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const SectionCard({super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OneirCard(
      radius: OneirRadius.md,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md + 2, vertical: OneirSpace.md + 2),
      elevated: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 24, child: Align(alignment: Alignment.bottomLeft, child: Icon(icon, size: 24, color: OneirColors.accentStrong))),
        const SizedBox(height: OneirSpace.sm),
        Text(label, style: OneirText.bodyStrong.copyWith(fontSize: 12.5), maxLines: 2),
      ]),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<bool> _checked = List.filled(kWidgetTasks.length, false);
  // The real, user-editable task list from the Tasks screen
  // (OneirProtection.saveTaskList/loadTaskList) -- previously Home never
  // read this at all, always showing the fixed 3-item kWidgetTasks demo
  // regardless of what was actually added on Tasks. Once the user has
  // added any real tasks, those take over this card; the fixed demo stays
  // as the very-first-run experience before that.
  List<Map<String, dynamic>> _realTasks = [];
  bool get _useRealTasks => _realTasks.isNotEmpty;

  bool _celebrating = false;
  StreamSubscription<Uri?>? _widgetLaunchSub;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _wireWidgetLaunches();
  }

  @override
  void dispose() {
    _widgetLaunchSub?.cancel();
    super.dispose();
  }

  /// Routes Quick Focus / Vanya Daily Check-in widget taps to the right
  /// screen -- both the cold-start case (app wasn't running; the tap is
  /// what launched it) and the warm case (app was already open on Home).
  /// See OneirWidgetService for how the native side carries the action.
  Future<void> _wireWidgetLaunches() async {
    final initial = await OneirWidgetService.consumeInitialLaunch();
    if (initial != null) _handleWidgetLaunch(initial);
    _widgetLaunchSub = OneirWidgetService.registerLaunchListener(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(OneirWidgetLaunch action) {
    if (!mounted) return;
    switch (action) {
      case OneirWidgetLaunch.focusSession:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusTimeScreen()));
        break;
      case OneirWidgetLaunch.quickAddTask:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen(autoFocusAdd: true))).then((_) => _refreshRealTasks());
        break;
    }
  }

  Future<void> _loadSavedState() async {
    final saved = await OneirProtection.loadTaskState();
    final realTasks = await OneirProtection.loadTaskList();
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        for (var i = 0; i < _checked.length && i < saved.length; i++) {
          _checked[i] = saved[i];
        }
      }
      _realTasks = realTasks;
    });
    _syncTodaysFocusWidget();
  }

  /// Re-reads the real task list -- called after returning from the Tasks
  /// screen so anything added/checked there shows up here immediately,
  /// not just on the next cold start.
  Future<void> _refreshRealTasks() async {
    final realTasks = await OneirProtection.loadTaskList();
    if (!mounted) return;
    setState(() => _realTasks = realTasks);
    _syncTodaysFocusWidget();
  }

  void _syncTodaysFocusWidget() {
    final tasks = _useRealTasks
        ? [for (final t in _realTasks) (label: t['label'] as String? ?? '', done: t['done'] as bool? ?? false)]
        : [for (var i = 0; i < kWidgetTasks.length; i++) (label: kWidgetTasks[i], done: _checked[i])];
    OneirWidgetService.updateTodaysFocus(tasks);
    // Widget 3's prompt reads this same task data (see
    // VanyaCheckInWidgetProvider.promptFor()) but only redraws on its own
    // OS-scheduled interval unless told to now -- without this, checking
    // off a task would only make the Check-in widget say "You're doing
    // well" the next time Android happened to refresh it on its own,
    // possibly not for a while.
    OneirWidgetService.refreshCheckIn();
  }

  Future<void> _toggle(int i) async {
    final wasUnchecked = !_checked[i];
    setState(() => _checked[i] = !_checked[i]);
    await OneirProtection.saveTaskState(_checked);
    _syncTodaysFocusWidget();
    // A real "win" moment: Vanya visibly celebrates the very first task you
    // complete on the actual Home screen, not just during onboarding demos --
    // this is the first genuine success the app can show back to you.
    if (wasUnchecked && _checked[i]) {
      setState(() => _celebrating = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _celebrating = false);
      });
    }
  }

  Widget _taskRow({required String label, required bool done, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OneirSpace.sm - 2),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16, height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: done ? OneirColors.accent : Colors.transparent,
              border: done ? null : Border.all(color: OneirColors.border, width: 1.5),
            ),
            child: done ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
          ),
          const SizedBox(width: OneirSpace.sm + 2),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: (done ? OneirText.bodyStrong.copyWith(color: OneirColors.textFaint, fontSize: 13) : OneirText.bodyStrong.copyWith(fontSize: 13)).copyWith(
                decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleReal(int i) async {
    final wasUnchecked = !(_realTasks[i]['done'] as bool? ?? false);
    setState(() => _realTasks[i]['done'] = !(_realTasks[i]['done'] as bool? ?? false));
    await OneirProtection.saveTaskList(_realTasks);
    _syncTodaysFocusWidget();
    if (wasUnchecked && (_realTasks[i]['done'] as bool)) {
      setState(() => _celebrating = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _celebrating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(OneirSpace.xxl, OneirSpace.xxl + 2, OneirSpace.xxl, OneirSpace.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning, ${widget.name.isEmpty ? "Alex" : widget.name}', style: OneirText.heading),
                    const SizedBox(height: 2),
                    Text('Tue, 22 Jul', style: OneirText.caption.copyWith(letterSpacing: 0)),
                  ],
                ),
              ),
              Material(
                color: OneirColors.surfaceSunken,
                borderRadius: BorderRadius.circular(OneirRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(OneirRadius.sm),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Padding(
                    padding: EdgeInsets.all(OneirSpace.md - 2),
                    child: Icon(Icons.settings_outlined, size: 22, color: OneirColors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OneirSpace.xl),
          OneirCard(
            radius: OneirRadius.xl,
            padding: const EdgeInsets.fromLTRB(OneirSpace.xl, OneirSpace.lg + 2, OneirSpace.lg, OneirSpace.lg + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text("Today's Adventure", style: OneirText.title.copyWith(fontSize: 15)),
                    const SizedBox(height: OneirSpace.sm + 2),
                    // Once real tasks exist (added via the Tasks screen),
                    // they replace the fixed 3-item starter demo here --
                    // previously this card always showed the same
                    // "Say hi to Vanya / Finish Biology / Read 10 pages"
                    // placeholder forever, regardless of what was actually
                    // added elsewhere in the app.
                    if (_useRealTasks)
                      for (var i = 0; i < _realTasks.length; i++) _taskRow(
                        label: _realTasks[i]['label'] as String? ?? '',
                        done: _realTasks[i]['done'] as bool? ?? false,
                        onTap: () => _toggleReal(i),
                      )
                    else
                      for (var i = 0; i < kWidgetTasks.length; i++) _taskRow(
                        label: kWidgetTasks[i],
                        done: _checked[i],
                        onTap: () => _toggle(i),
                      ),
                  ]),
                ),
                const SizedBox(width: OneirSpace.sm + 2),
                // Real expression swap now, not just a differently-keyed copy
                // of the same asset -- this AnimatedSwitcher used to
                // crossfade between two VanyaAnimation widgets that both
                // rendered the identical hello/wave loop, so _celebrating
                // toggling never actually changed what was on screen.
                // VanyaCharacter gives each branch its own real pose: a
                // genuine cheer for finishing today's tasks, a calm
                // settled-in moment (her tea) the rest of the time --
                // matching the brief's "Vanya sitting there with her little
                // tea" home-screen centerpiece.
                //
                // Bumped from 88x88 (she read as small/washed-out next to
                // this much white card) up to 128x128, with a soft
                // lavender glow behind her -- there's no dimming filter
                // anywhere on VanyaCharacter itself to remove, so size plus
                // a bit of background warmth is what actually moves the
                // needle here.
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [OneirColors.accent.withOpacity(0.24), OneirColors.accent.withOpacity(0)],
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _celebrating
                        ? const VanyaCharacter(key: ValueKey('cheer'), expression: VanyaExpression.proud, width: 128, height: 128)
                        : const VanyaCharacter(key: ValueKey('tea'), expression: VanyaExpression.content, width: 128, height: 128),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OneirSpace.xxl - 2),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: OneirSpace.md, crossAxisSpacing: OneirSpace.md,
            childAspectRatio: 1.3,
            children: [
              SectionCard(
                label: 'Tasks',
                icon: Icons.checklist_rounded,
                // Reload the real task list on return so anything
                // added/checked on the Tasks screen shows up in "Today's
                // Adventure" above immediately -- not just next cold start.
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen()));
                  _refreshRealTasks();
                },
              ),
              SectionCard(
                label: 'Protected Apps',
                icon: Icons.shield_outlined,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProtectedAppsScreen(onNext: () => Navigator.of(context).pop(), isStandalone: true),
                )),
              ),
              SectionCard(
                label: 'Focus Time',
                icon: Icons.local_cafe_outlined,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusTimeScreen())),
              ),
              SectionCard(
                label: 'Statistics',
                icon: Icons.insights_outlined,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen())),
              ),
            ],
          ),
          const SizedBox(height: OneirSpace.xxl - 2),
          Text('Your streaks', style: OneirText.title.copyWith(fontSize: 15)),
          const SizedBox(height: OneirSpace.sm + 2),
          Row(
            children: [
              Expanded(
                child: OneirStreakWidgetCard(
                  title: 'Focus Streak',
                  currentDay: 3,
                  totalDays: 30,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusTimeScreen())),
                ),
              ),
              const SizedBox(width: OneirSpace.md),
              Expanded(
                child: OneirStreakWidgetCard(
                  title: 'Study Streak',
                  currentDay: 0,
                  totalDays: 14,
                  locked: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Complete a few more tasks to unlock Study Streak.', style: OneirText.bodySmall.copyWith(color: Colors.white))),
                  ),
                ),
              ),
            ],
          ),
        ]),
        ),
      ),
    );
  }
}
