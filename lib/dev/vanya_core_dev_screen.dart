import 'package:flutter/material.dart';

import '../features/home/home_screen.dart' show triggerInterventionFor;
import '../features/intervention/intervention_controller.dart';
import '../models/protected_app.dart';
import '../models/vanya_decision.dart';
import '../models/vanya_task.dart';
import '../native/vanya_permissions.dart';
import '../services/app_access_controller.dart';
import '../services/intervention_history_service.dart';
import '../services/mock_vanya_reasoning_service.dart';
import '../services/protected_app_service.dart';
import '../services/task_service.dart';
import '../services/temporary_access_service.dart';

/// Development-only scenario switches for the functional core (tasks,
/// protected apps, temporary access, the intervention flow) — kept in its
/// own screen, reached only from a debug icon on the homepage, so it's
/// trivial to delete or gate behind a build flag later without touching
/// production UI. Nothing here talks to a widget directly; every action
/// goes through the same services/[AppAccessController] the real UI uses.
class VanyaCoreDevScreen extends StatefulWidget {
  const VanyaCoreDevScreen({
    super.key,
    required this.taskService,
    required this.protectedAppService,
    required this.temporaryAccessService,
    required this.historyService,
    required this.access,
    required this.reasoningService,
  });

  final TaskService taskService;
  final ProtectedAppService protectedAppService;
  final TemporaryAccessService temporaryAccessService;
  final InterventionHistoryService historyService;
  final AppAccessController access;
  final MockVanyaReasoningService reasoningService;

  @override
  State<VanyaCoreDevScreen> createState() => _VanyaCoreDevScreenState();
}

class _VanyaCoreDevScreenState extends State<VanyaCoreDevScreen>
    with WidgetsBindingObserver {
  bool? _usageAccessGranted;
  bool? _accessibilityGranted;
  bool? _overlayGranted;
  String? _lastDetectedPackage;
  String? _selectedAppForAccessCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionsAndDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permissions are granted in system Settings, outside this app — pick
    // up the real state whenever the user comes back, same as the
    // onboarding permission screens do.
    if (state == AppLifecycleState.resumed) _refreshPermissionsAndDetection();
  }

  Future<void> _refreshPermissionsAndDetection() async {
    final results = await Future.wait([
      VanyaPermissions.hasUsageAccess(),
      VanyaPermissions.isAccessibilityServiceEnabled(),
      VanyaPermissions.canDrawOverlays(),
      VanyaPermissions.getLastDetectedForegroundPackage(),
    ]);
    if (!mounted) return;
    setState(() {
      _usageAccessGranted = results[0] as bool;
      _accessibilityGranted = results[1] as bool;
      _overlayGranted = results[2] as bool;
      _lastDetectedPackage = results[3] as String?;
    });
  }

  ProtectedApp get _devApp {
    final apps = widget.protectedAppService.apps;
    if (apps.isNotEmpty) return apps.first;
    // Not persisted — just enough of an app to exercise the flow when the
    // user hasn't added any protected apps yet.
    return const ProtectedApp(packageName: 'dev.sample.app', displayName: 'Sample App (dev)');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _seedActiveTask() async {
    final now = DateTime.now();
    await widget.taskService.addTask(
      VanyaTask(
        id: 'dev-active-${now.microsecondsSinceEpoch}',
        title: 'Science homework (dev sample)',
        date: DateTime(now.year, now.month, now.day),
        startTime: TimeOfDay.fromDateTime(now.subtract(const Duration(minutes: 10))),
        endTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 20))),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _snack('Seeded a task active right now.');
  }

  /// Case C — a completed task should never be treated as current, even
  /// though its time window still contains "now".
  Future<void> _seedCompletedActiveTask() async {
    final now = DateTime.now();
    await widget.taskService.addTask(
      VanyaTask(
        id: 'dev-completed-${now.microsecondsSinceEpoch}',
        title: 'Completed task (dev sample, Case C)',
        date: DateTime(now.year, now.month, now.day),
        startTime: TimeOfDay.fromDateTime(now.subtract(const Duration(minutes: 10))),
        endTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 20))),
        completed: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _snack('Seeded a completed task whose window covers now — should NOT show as current.');
  }

  /// Case D — a task whose end time has already passed should not be
  /// treated as current either.
  Future<void> _seedEndedTask() async {
    final now = DateTime.now();
    await widget.taskService.addTask(
      VanyaTask(
        id: 'dev-ended-${now.microsecondsSinceEpoch}',
        title: 'Ended task (dev sample, Case D)',
        date: DateTime(now.year, now.month, now.day),
        startTime: TimeOfDay.fromDateTime(now.subtract(const Duration(minutes: 30))),
        endTime: TimeOfDay.fromDateTime(now.subtract(const Duration(minutes: 5))),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _snack('Seeded a task that already ended — should NOT show as current.');
  }

  Future<void> _clearTodaysTasks() async {
    for (final task in widget.taskService.todaysTasks) {
      await widget.taskService.deleteTask(task.id);
    }
    _snack("Cleared today's tasks — no current task now.");
  }

  Future<void> _triggerWithForcedDecision(VanyaDecisionType? type) async {
    widget.reasoningService.forcedDecision = type;
    try {
      await triggerInterventionFor(
        context,
        app: _devApp,
        access: widget.access,
        controller: InterventionController(flow: widget.access.flow),
      );
    } finally {
      widget.reasoningService.forcedDecision = null;
    }
  }

  Future<void> _createGrant({required bool alreadyExpired}) async {
    final app = _devApp;
    if (alreadyExpired) {
      // A negative duration lands expiresAt in the past — same model, no
      // special-cased "backdated" path needed.
      await widget.temporaryAccessService.createGrant(
        packageName: app.packageName,
        duration: const Duration(seconds: -1),
        reason: 'dev: pre-expired grant',
        source: 'dev_tools',
      );
      setState(() {});
      _snack('Created an already-expired grant for ${app.displayName}.');
      return;
    }
    final grant = await widget.temporaryAccessService.createGrant(
      packageName: app.packageName,
      duration: const Duration(minutes: 5),
      reason: 'dev: manual grant',
      source: 'dev_tools',
    );
    setState(() {});
    _snack('Active grant for ${app.displayName} until ${grant.expiresAt.toIso8601String()}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev tools — functional core')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'DEVELOPMENT ONLY — Android enforcement',
            children: [
              Text(
                'Permission status, foreground detection, and enforcement '
                'wiring for manual testing. Not the final onboarding UI.',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
          _Section(
            title: 'Permissions',
            children: [
              _PermissionRow(
                label: 'Usage Access',
                granted: _usageAccessGranted,
                onOpenSettings: VanyaPermissions.openUsageAccessSettings,
              ),
              _PermissionRow(
                label: 'Accessibility Service',
                granted: _accessibilityGranted,
                onOpenSettings: VanyaPermissions.openAccessibilitySettings,
              ),
              _PermissionRow(
                label: 'Display Over Other Apps',
                granted: _overlayGranted,
                onOpenSettings: VanyaPermissions.openOverlaySettings,
              ),
              _DevButton(label: 'Refresh permission status', onPressed: _refreshPermissionsAndDetection),
            ],
          ),
          _Section(
            title: 'Foreground-app detection',
            children: [
              Text(
                'Last package VanyaAccessibilityService observed:',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                _lastDetectedPackage ?? '(none yet — open another app while Accessibility is on)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          _Section(
            title: 'Access check',
            children: [
              if (widget.protectedAppService.apps.isEmpty)
                const Text('Add a protected app first.', style: TextStyle(fontSize: 12, color: Colors.black54))
              else ...[
                DropdownButton<String>(
                  value: _selectedAppForAccessCheck ?? widget.protectedAppService.apps.first.packageName,
                  isExpanded: true,
                  items: [
                    for (final app in widget.protectedAppService.apps)
                      DropdownMenuItem(value: app.packageName, child: Text(app.displayName)),
                  ],
                  onChanged: (value) => setState(() => _selectedAppForAccessCheck = value),
                ),
                Builder(
                  builder: (context) {
                    final pkg = _selectedAppForAccessCheck ?? widget.protectedAppService.apps.first.packageName;
                    final hasAccess = widget.temporaryAccessService.hasActiveAccess(pkg);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        hasAccess ? 'Currently has valid temporary access.' : 'No valid temporary access right now.',
                        style: TextStyle(fontSize: 13, color: hasAccess ? Colors.green.shade700 : Colors.black54),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          _Section(
            title: 'Current-task scenarios (A–D)',
            children: [
              _DevButton(label: 'A: Seed task active right now', onPressed: _seedActiveTask),
              _DevButton(label: 'B: Clear today\'s tasks (no current task)', onPressed: _clearTodaysTasks),
              _DevButton(label: 'C: Seed a completed task covering now', onPressed: _seedCompletedActiveTask),
              _DevButton(label: 'D: Seed a task that already ended', onPressed: _seedEndedTask),
            ],
          ),
          _Section(
            title: 'Trigger intervention — for real, type a reason on the screen',
            children: [
              _DevButton(
                label: 'Trigger with mock reasoning (type your own reason)',
                onPressed: () => _triggerWithForcedDecision(null),
              ),
            ],
          ),
          _Section(
            title: 'Trigger intervention — forced outcome (skips reasoning)',
            children: [
              _DevButton(
                label: 'Force REDIRECT',
                onPressed: () => _triggerWithForcedDecision(VanyaDecisionType.redirect),
              ),
              _DevButton(
                label: 'Force ALLOW_TEMPORARY_ACCESS',
                onPressed: () => _triggerWithForcedDecision(VanyaDecisionType.allowTemporaryAccess),
              ),
              _DevButton(
                label: 'Force ALLOW',
                onPressed: () => _triggerWithForcedDecision(VanyaDecisionType.allow),
              ),
              _DevButton(
                label: 'Force DENY',
                onPressed: () => _triggerWithForcedDecision(VanyaDecisionType.deny),
              ),
            ],
          ),
          _Section(
            title: 'Temporary access',
            children: [
              _DevButton(
                label: 'Create active 5-min grant',
                onPressed: () => _createGrant(alreadyExpired: false),
              ),
              _DevButton(
                label: 'Create already-expired grant',
                onPressed: () => _createGrant(alreadyExpired: true),
              ),
              const SizedBox(height: 8),
              ...widget.temporaryAccessService.grants.map(
                (g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${g.packageName} — ${g.isActive ? "ACTIVE" : "expired/revoked"} — expires ${g.expiresAt.toIso8601String()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Intervention history (persisted)',
            children: [
              if (widget.historyService.all.isEmpty)
                const Text('No interventions recorded yet.', style: TextStyle(fontSize: 12, color: Colors.black54))
              else
                for (final entry in widget.historyService.all.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${entry.timestamp.toIso8601String()} — ${entry.appDisplayName} — '
                      '${entry.decisionType.name}'
                      '${entry.temporaryAccessDuration != null ? " (${entry.temporaryAccessDuration!.inMinutes}m)" : ""}'
                      ' — task: ${entry.currentTaskTitle ?? "none"} — reason: "${entry.userReason ?? ""}"',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// One row of the item-13 permission mock-up:
/// `Usage Access [Granted]` / `Accessibility Service [Not granted] [Open Settings]`.
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onOpenSettings,
  });

  final String label;
  final bool? granted;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isGranted = granted == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: granted == null
                  ? Colors.black12
                  : (isGranted ? Colors.green.shade100 : Colors.red.shade100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              granted == null ? '…' : (isGranted ? 'Granted' : 'Not granted'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: granted == null
                    ? Colors.black54
                    : (isGranted ? Colors.green.shade900 : Colors.red.shade900),
              ),
            ),
          ),
          if (granted != true) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onOpenSettings, child: const Text('Open Settings')),
          ],
        ],
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}
