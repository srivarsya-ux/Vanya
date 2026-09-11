import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vanya_task.dart';

/// The single source of truth for what the user planned to be doing —
/// tasks are not just homepage content. Vanya's future intervention system
/// asks this service what's current/next rather than each screen computing
/// it independently (see `getCurrentTask`/`getNextTask`).
class TaskService extends ChangeNotifier {
  TaskService._();

  static const _prefsKey = 'vanya_tasks_v1';

  final List<VanyaTask> _tasks = [];
  List<VanyaTask> get allTasks => List.unmodifiable(_tasks);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> _pendingWrite = Future.value();

  static Future<TaskService> load() async {
    final service = TaskService._();
    await service._load();
    return service;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      for (final entry in raw) {
        try {
          _tasks.add(VanyaTask.fromJson(jsonDecode(entry) as Map<String, dynamic>));
        } catch (_) {
          // Skip a corrupt entry rather than losing every task.
        }
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _tasks.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  void _commit() {
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) => _persist());
  }

  Future<void> flush() => _pendingWrite;

  List<VanyaTask> get todaysTasks {
    final today = _tasks.where((t) => t.isToday).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return today;
  }

  Future<void> addTask(VanyaTask task) async {
    _tasks.add(task);
    _commit();
  }

  Future<void> updateTask(VanyaTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    _commit();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _commit();
  }

  Future<void> toggleComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(completed: !task.completed);
    _commit();
  }

  /// The task whose time window contains [at] (defaults to now) among
  /// today's tasks. This is the function the future intervention system
  /// calls to know what the user meant to be doing right now.
  ///
  /// A completed task is never "current" even if [at] still falls inside
  /// its time window — marking a task done means the user isn't supposed
  /// to be doing it anymore, so it shouldn't be used as a reason to
  /// intervene. A task whose end time has passed is likewise never
  /// current; [VanyaTask.isActiveAt] already excludes it.
  VanyaTask? getCurrentTask({DateTime? at}) {
    final moment = at ?? DateTime.now();
    for (final task in todaysTasks) {
      if (task.completed) continue;
      if (task.isActiveAt(moment)) return task;
    }
    return null;
  }

  bool get hasCurrentTask => getCurrentTask() != null;

  /// The soonest today's task that hasn't started yet.
  VanyaTask? getNextTask({DateTime? at}) {
    final moment = at ?? DateTime.now();
    final upcoming = todaysTasks.where((t) => t.startDateTime.isAfter(moment)).toList();
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  /// The most recently *ended* today's task, regardless of completion —
  /// useful for reasoning like "what were they just doing."
  VanyaTask? getMostRecentTask({DateTime? at}) {
    final moment = at ?? DateTime.now();
    final past = todaysTasks.where((t) => t.endDateTime.isBefore(moment) || t.endDateTime.isAtSameMomentAs(moment)).toList();
    if (past.isEmpty) return null;
    return past.last;
  }

  /// How much time is left on the current task, or null if there isn't one.
  Duration? currentTaskTimeRemaining({DateTime? at}) {
    final moment = at ?? DateTime.now();
    final current = getCurrentTask(at: moment);
    if (current == null) return null;
    return current.endDateTime.difference(moment);
  }
}
