import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';
import '../stats/oneir_event_log.dart';

/// Real numbers pulled from OneirEventLog -- the persisted event log that
/// this screen's own previous version admitted didn't exist yet ("a
/// fuller history/trends view would need a real event log the app
/// doesn't keep yet"). It exists now (see lib/stats/oneir_event_log.dart,
/// logged from InterventionController on every real allow/redirect
/// decision and from FocusTimeScreen on every completed session), so this
/// screen reads real history instead of just today's task-completion
/// counts.
///
/// One deliberate substitution from the brief's exact example numbers:
/// §08 asks for "Protected time -- 3h 42m," which would mean something
/// like "how long were you kept away from apps," a number that can't be
/// computed honestly without full Android usage-stats mining this app
/// doesn't do. "Focus time" (the real, logged sum of completed Focus Mode
/// sessions) fills the same slot in the layout with a number that is
/// actually true. "Interruptions avoided," "Focus sessions," and "Most
/// protected app" are all real and computed exactly as named.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  int _protectedAppCount = 0;
  int _tasksCompleted = 0;
  int _tasksTotal = 0;
  String _reason = '';

  int _interruptionsAvoided = 0;
  int _focusSessions = 0;
  int _focusMinutes = 0;
  String? _mostProtectedApp;
  List<int> _dailyRedirects = List.filled(7, 0);
  int _lastWeekInterruptions = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await OneirProtection.loadProtectedApps();
    final taskList = await OneirProtection.loadTaskList();
    final homeTaskState = await OneirProtection.loadTaskState();
    final reason = await OneirProtection.loadUserReason();

    final homeCompleted = homeTaskState?.where((t) => t).length ?? 0;
    final homeTotal = homeTaskState?.length ?? 0;
    final listCompleted = taskList.where((t) => t['done'] == true).length;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final weekStart = startOfToday.subtract(const Duration(days: 6)); // rolling 7-day window, today included
    final priorWeekStart = weekStart.subtract(const Duration(days: 7));

    final thisWeekEvents = await OneirEventLog.loadSince(weekStart);
    final priorWeekAll = await OneirEventLog.loadSince(priorWeekStart);
    final priorWeekOnly = priorWeekAll.where((e) => e.timestamp.isBefore(weekStart));

    final redirects = thisWeekEvents.where((e) => e.type == OneirEventType.interventionRedirect).toList();
    final focusSessions = thisWeekEvents.where((e) => e.type == OneirEventType.focusSessionCompleted).toList();
    final interventions = thisWeekEvents.where(
      (e) => e.type == OneirEventType.interventionRedirect || e.type == OneirEventType.interventionAllow,
    );

    final appCounts = <String, int>{};
    for (final e in interventions) {
      if (e.appLabel == null || e.appLabel!.isEmpty) continue;
      appCounts[e.appLabel!] = (appCounts[e.appLabel!] ?? 0) + 1;
    }
    String? topApp;
    var topCount = 0;
    appCounts.forEach((label, count) {
      if (count > topCount) {
        topCount = count;
        topApp = label;
      }
    });

    final dailyRedirects = List.filled(7, 0);
    for (final e in redirects) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      final index = day.difference(weekStart).inDays;
      if (index >= 0 && index < 7) dailyRedirects[index]++;
    }

    final lastWeekInterruptions = priorWeekOnly.where((e) => e.type == OneirEventType.interventionRedirect).length;

    if (!mounted) return;
    setState(() {
      _protectedAppCount = apps.length;
      _tasksCompleted = homeCompleted + listCompleted;
      _tasksTotal = homeTotal + taskList.length;
      _reason = reason;

      _interruptionsAvoided = redirects.length;
      _focusSessions = focusSessions.length;
      _focusMinutes = focusSessions.fold<int>(0, (sum, e) => sum + (e.minutes ?? 0));
      _mostProtectedApp = topApp;
      _dailyRedirects = dailyRedirects;
      _lastWeekInterruptions = lastWeekInterruptions;

      _loading = false;
    });
  }

  /// One real, computed line -- not a static string. Compares this
  /// week's actual redirect count against last week's, so it's either
  /// genuinely true or, when there isn't enough history yet, honestly
  /// says so instead of guessing.
  String _weekSummaryLine() {
    final hasAnyHistory = _lastWeekInterruptions > 0 || _interruptionsAvoided > 0 || _focusSessions > 0;
    if (!hasAnyHistory) {
      return "Not much history yet -- let's see how this week goes.";
    }
    if (_interruptionsAvoided == 0 && _lastWeekInterruptions == 0) {
      return "Vanya hasn't had to step in this week.";
    }
    if (_interruptionsAvoided < _lastWeekInterruptions) {
      return _mostProtectedApp != null
          ? "You reached for $_mostProtectedApp less this week."
          : 'You reached for protected apps less this week.';
    }
    if (_interruptionsAvoided > _lastWeekInterruptions) {
      return 'This was a harder week -- that happens.';
    }
    return 'About the same as last week.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('Statistics', style: OneirText.title.copyWith(fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OneirColors.accent))
          : ListView(
              padding: const EdgeInsets.all(OneirSpace.xl),
              children: [
                Text('This week', style: OneirText.eyebrow),
                const SizedBox(height: OneirSpace.sm + 2),
                Row(children: [
                  Expanded(child: _StatCard(label: 'Interruptions avoided', value: '$_interruptionsAvoided')),
                  const SizedBox(width: OneirSpace.md),
                  Expanded(child: _StatCard(label: 'Focus sessions', value: '$_focusSessions')),
                ]),
                const SizedBox(height: OneirSpace.md),
                Row(children: [
                  Expanded(child: _StatCard(label: 'Focus time', value: _focusMinutes > 0 ? '${_focusMinutes ~/ 60}h ${_focusMinutes % 60}m' : '0m')),
                  const SizedBox(width: OneirSpace.md),
                  Expanded(child: _StatCard(label: 'Most protected app', value: _mostProtectedApp ?? '—')),
                ]),
                const SizedBox(height: OneirSpace.xxl),
                _WeekBars(dailyRedirects: _dailyRedirects),
                const SizedBox(height: OneirSpace.lg),
                OneirCard(
                  padding: const EdgeInsets.all(OneirSpace.lg),
                  elevated: false,
                  child: Text(
                    _weekSummaryLine(),
                    style: OneirText.bodyStrong.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: OneirSpace.xxxl - 8),
                Text('Today', style: OneirText.eyebrow),
                const SizedBox(height: OneirSpace.sm + 2),
                Row(children: [
                  Expanded(child: _StatCard(label: 'Tasks completed', value: '$_tasksCompleted / $_tasksTotal')),
                  const SizedBox(width: OneirSpace.md),
                  Expanded(child: _StatCard(label: 'Protected apps', value: '$_protectedAppCount')),
                ]),
                const SizedBox(height: OneirSpace.md),
                if (_reason.isNotEmpty)
                  OneirCard(
                    padding: const EdgeInsets.all(OneirSpace.lg),
                    elevated: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why you started', style: OneirText.eyebrow),
                        const SizedBox(height: OneirSpace.sm - 2),
                        Text(_reason, style: OneirText.bodyStrong),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return OneirCard(
      padding: const EdgeInsets.all(OneirSpace.lg),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: OneirText.heading.copyWith(fontSize: 22)),
          const SizedBox(height: OneirSpace.xs),
          Text(label, style: OneirText.caption),
        ],
      ),
    );
  }
}

/// The brief's "a simple visual showing improvement" -- seven real daily
/// counts (interruptions redirected, oldest to today), not a full charting
/// library. Deliberately one metric, one color (the app's single accent),
/// no legend, no axis labels beyond day initials -- this is meant to be
/// glanced at, not analyzed.
class _WeekBars extends StatelessWidget {
  final List<int> dailyRedirects;
  const _WeekBars({required this.dailyRedirects});

  @override
  Widget build(BuildContext context) {
    final maxValue = dailyRedirects.fold<int>(1, (m, v) => v > m ? v : m);
    final now = DateTime.now();
    const dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return OneirCard(
      padding: const EdgeInsets.fromLTRB(OneirSpace.lg, OneirSpace.lg, OneirSpace.lg, OneirSpace.sm + 2),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your week', style: OneirText.eyebrow),
          const SizedBox(height: OneirSpace.md + 2),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: OneirSpace.sm),
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: dailyRedirects[i] == 0 ? 0.06 : (dailyRedirects[i] / maxValue).clamp(0.12, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dailyRedirects[i] == 0 ? OneirColors.border : OneirColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: OneirSpace.sm),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: OneirSpace.sm),
                Expanded(
                  child: Text(
                    dayLetters[now.subtract(Duration(days: 6 - i)).weekday % 7],
                    textAlign: TextAlign.center,
                    style: OneirText.caption.copyWith(fontSize: 10, letterSpacing: 0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
