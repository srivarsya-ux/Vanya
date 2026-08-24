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
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          OneirProgressHeader(progress: 15 / 18, onBack: widget.onBack),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Widget card -- Row+Expanded instead of Stack+Positioned+manually
          // -reserved padding: Flutter's layout engine allocates the space
          // itself here, so this cannot overflow regardless of task label
          // length or card width, unlike guessing a pixel margin by hand.
          Container(
            decoration: BoxDecoration(
              color: OneirColors.cardNeutral,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text("Today's Adventure", style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 16, color: OneirColors.text)),
                    const SizedBox(height: 14),
                    for (var i = 0; i < kWidgetTasks.length; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() => _checked[i] = !_checked[i]);
                          _persist();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: _checked[i] ? OneirColors.text : Colors.transparent,
                                border: _checked[i] ? null : Border.all(color: OneirColors.border, width: 1.5),
                              ),
                              child: _checked[i] ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                kWidgetTasks[i],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans', fontSize: 14,
                                  color: _checked[i] ? const Color(0xFFB0B0B0) : OneirColors.text,
                                  decoration: _checked[i] ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 6,
                        backgroundColor: const Color(0xFFE5E5E5),
                        valueColor: const AlwaysStoppedAnimation(OneirColors.text),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                const VanyaAnimation(width: 104, height: 104),
              ],
            ),
          ),
          const SizedBox(height: 28),
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
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Your widgets remind you what matters before you even think about scrolling.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20.6, height: 1.5, color: OneirColors.textMuted),
            ),
          ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
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
    return Material(
      color: OneirColors.cardNeutral,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 24, child: Align(alignment: Alignment.bottomLeft, child: Icon(icon, size: 24, color: OneirColors.textMuted))),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12.5, fontWeight: FontWeight.w500, color: OneirColors.text), maxLines: 2),
          ]),
        ),
      ),
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen(autoFocusAdd: true)));
        break;
    }
  }

  Future<void> _loadSavedState() async {
    final saved = await OneirProtection.loadTaskState();
    if (!mounted || saved == null) return;
    setState(() {
      for (var i = 0; i < _checked.length && i < saved.length; i++) {
        _checked[i] = saved[i];
      }
    });
    _syncTodaysFocusWidget();
  }

  void _syncTodaysFocusWidget() {
    final tasks = [for (var i = 0; i < kWidgetTasks.length; i++) (label: kWidgetTasks[i], done: _checked[i])];
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

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning, ${widget.name.isEmpty ? "Alex" : widget.name}',
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.4, color: OneirColors.text)),
                    const SizedBox(height: 2),
                    const Text('Tue, 22 Jul', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
                  ],
                ),
              ),
              Material(
                color: OneirColors.cardNeutral,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.settings_outlined, size: 22, color: OneirColors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: OneirColors.cardNeutral,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text("Today's Adventure", style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < kWidgetTasks.length; i++)
                      GestureDetector(
                        onTap: () => _toggle(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: _checked[i] ? OneirColors.text : Colors.transparent,
                                border: _checked[i] ? null : Border.all(color: OneirColors.border, width: 1.5),
                              ),
                              child: _checked[i] ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                kWidgetTasks[i],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans', fontSize: 13,
                                  color: _checked[i] ? const Color(0xFFB0B0B0) : OneirColors.text,
                                  decoration: _checked[i] ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 10),
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _celebrating
                      ? const VanyaCharacter(key: ValueKey('cheer'), expression: VanyaExpression.proud, width: 88, height: 88)
                      : const VanyaCharacter(key: ValueKey('tea'), expression: VanyaExpression.content, width: 88, height: 88),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              SectionCard(
                label: 'Tasks',
                icon: Icons.checklist_rounded,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen())),
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
          const SizedBox(height: 22),
          Text('Your streaks', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
          const SizedBox(height: 10),
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
              const SizedBox(width: 12),
              Expanded(
                child: OneirStreakWidgetCard(
                  title: 'Study Streak',
                  currentDay: 0,
                  totalDays: 14,
                  locked: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete a few more tasks to unlock Study Streak.', style: TextStyle(fontFamily: 'PlusJakartaSans'))),
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
