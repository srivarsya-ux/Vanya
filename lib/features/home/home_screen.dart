import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dev/vanya_core_dev_screen.dart';
import '../../models/protected_app.dart';
import '../../models/vanya_task.dart';
import '../../services/app_access_controller.dart';
import '../../services/core_services.dart';
import '../../services/protected_app_service.dart';
import '../../services/task_service.dart';
import '../../services/temporary_access_service.dart';
import '../intervention/intervention_controller.dart';
import '../intervention/intervention_screen.dart';
import 'widgets/add_edit_task_sheet.dart';
import 'widgets/add_protected_app_sheet.dart';

/// The real functional homepage — plain Material placeholder UI on
/// purpose. This is the foundation the rest of the app (Vanya artwork,
/// final visual design, real enforcement) plugs into later; nothing here
/// should need rewriting when that happens, just restyling.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CoreServices? _services;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = await CoreServices.load();
    if (!mounted) return;
    setState(() => _services = services);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final taskService = services.taskService;
    final protectedAppService = services.protectedAppService;
    final temporaryAccessService = services.temporaryAccessService;
    final historyService = services.historyService;
    final access = services.access;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: taskService),
        ChangeNotifierProvider.value(value: protectedAppService),
        ChangeNotifierProvider.value(value: temporaryAccessService),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vanya — Home (functional core)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.build_outlined),
              tooltip: 'Dev tools',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VanyaCoreDevScreen(
                    taskService: taskService,
                    protectedAppService: protectedAppService,
                    temporaryAccessService: temporaryAccessService,
                    historyService: historyService,
                    access: access,
                    reasoningService: services.reasoningService,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TodaySummary(taskService: taskService),
            const SizedBox(height: 24),
            _TasksSection(taskService: taskService),
            const SizedBox(height: 24),
            _ProtectedAppsSection(
              protectedAppService: protectedAppService,
              temporaryAccessService: temporaryAccessService,
              access: access,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.taskService});

  final TaskService taskService;

  @override
  Widget build(BuildContext context) {
    context.watch<TaskService>();
    final now = DateTime.now();
    final current = taskService.getCurrentTask();
    final next = taskService.getNextTask();
    final remaining = taskService.currentTaskTimeRemaining();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          if (current != null) ...[
            const Text('CURRENT TASK', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
            Text(current.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (remaining != null)
              Text('${remaining.inMinutes} min remaining', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ] else
            const Text('No current task', style: TextStyle(fontSize: 16, color: Colors.black54)),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text('Next: ${next.title} at ${next.startTime.format(context)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.taskService});

  final TaskService taskService;

  @override
  Widget build(BuildContext context) {
    context.watch<TaskService>();
    final tasks = taskService.todaysTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's tasks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: () async {
                final task = await AddEditTaskSheet.show(context);
                if (task != null) await taskService.addTask(task);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add task'),
            ),
          ],
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing planned for today yet.', style: TextStyle(color: Colors.black54)),
          )
        else
          for (final task in tasks) _TaskRow(task: task, taskService: taskService),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.taskService});

  final VanyaTask task;
  final TaskService taskService;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => taskService.toggleComplete(task.id),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: task.completed ? Colors.black45 : null,
        ),
      ),
      subtitle: Text('${task.startTime.format(context)} – ${task.endTime.format(context)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final updated = await AddEditTaskSheet.show(context, existing: task);
              if (updated != null) await taskService.updateTask(updated);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => taskService.deleteTask(task.id),
          ),
        ],
      ),
    );
  }
}

/// Manually triggers the real intervention flow for [app] — this is the
/// "development button on the homepage" the flow is meant to be exercised
/// from before there's real Android app detection to trigger it
/// automatically. Always resets [controller] once the screen closes,
/// however it closed, so no stale intervention state survives into the
/// next trigger (back navigation, a completed decision — every exit path
/// goes through this same cleanup).
Future<void> triggerInterventionFor(
  BuildContext context, {
  required ProtectedApp app,
  required AppAccessController access,
  required InterventionController controller,
}) async {
  final started = controller.start(app);
  if (!started) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${app.displayName} already has active temporary access — allowed with no intervention.')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => InterventionScreen(controller: controller)),
  );
  controller.reset();
}

class _ProtectedAppsSection extends StatelessWidget {
  const _ProtectedAppsSection({
    required this.protectedAppService,
    required this.temporaryAccessService,
    required this.access,
  });

  final ProtectedAppService protectedAppService;
  final TemporaryAccessService temporaryAccessService;
  final AppAccessController access;

  @override
  Widget build(BuildContext context) {
    context.watch<ProtectedAppService>();
    final apps = protectedAppService.apps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Protected apps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: () async {
                final app = await AddProtectedAppSheet.show(
                  context,
                  alreadyProtected: apps.map((a) => a.packageName).toSet(),
                );
                if (app != null) await protectedAppService.addApp(app);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add app'),
            ),
          ],
        ),
        if (apps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No protected apps yet.', style: TextStyle(color: Colors.black54)),
          )
        else
          for (final app in apps)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(app.displayName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.packageName, style: const TextStyle(fontSize: 11)),
                  _TemporaryAccessBadge(
                    packageName: app.packageName,
                    temporaryAccessService: temporaryAccessService,
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    tooltip: 'Simulate opening this app (dev)',
                    onPressed: () => triggerInterventionFor(
                      context,
                      app: app,
                      access: access,
                      controller: InterventionController(flow: access.flow),
                    ),
                  ),
                  Switch(
                    value: app.isProtected,
                    onChanged: (v) => protectedAppService.setProtected(app.packageName, v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => protectedAppService.removeApp(app.packageName),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// A small live countdown ("Temporary access: 4:32 left") shown under a
/// protected app whenever it has an active grant — this is what proves
/// [TemporaryAccessService] is checking real timestamps rather than an
/// in-memory countdown: refreshing this just re-reads `expiresAt` against
/// `DateTime.now()`.
class _TemporaryAccessBadge extends StatefulWidget {
  const _TemporaryAccessBadge({
    required this.packageName,
    required this.temporaryAccessService,
  });

  final String packageName;
  final TemporaryAccessService temporaryAccessService;

  @override
  State<_TemporaryAccessBadge> createState() => _TemporaryAccessBadgeState();
}

class _TemporaryAccessBadgeState extends State<_TemporaryAccessBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grant = widget.temporaryAccessService.activeGrantFor(widget.packageName);
    if (grant == null) return const SizedBox.shrink();
    final remaining = grant.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return Text(
      'Temporary access: $minutes:${seconds.toString().padLeft(2, '0')} left',
      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
    );
  }
}
