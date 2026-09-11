import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/intervention_context.dart';

/// Local, persisted log of completed interventions. Not a statistics
/// dashboard — just clean, queryable storage a future Statistics feature
/// and the reasoning service's "recent context" can both read.
class InterventionHistoryService extends ChangeNotifier {
  InterventionHistoryService._();

  static const _prefsKey = 'vanya_intervention_history_v1';

  /// Recent-context lists handed to reasoning are capped at this many
  /// entries — see `recent`.
  static const int recentContextLimit = 5;

  final List<InterventionHistoryEntry> _entries = [];
  List<InterventionHistoryEntry> get all => List.unmodifiable(_entries);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> _pendingWrite = Future.value();

  static Future<InterventionHistoryService> load() async {
    final service = InterventionHistoryService._();
    await service._load();
    return service;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null) {
      for (final entry in raw) {
        try {
          _entries.add(
            InterventionHistoryEntry.fromJson(jsonDecode(entry) as Map<String, dynamic>),
          );
        } catch (_) {}
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void _commit() {
    notifyListeners();
    _pendingWrite = _pendingWrite.then((_) => _persist());
  }

  Future<void> flush() => _pendingWrite;

  Future<void> record(InterventionHistoryEntry entry) async {
    _entries.add(entry);
    _commit();
  }

  /// The most recent entries, oldest-first, capped at
  /// [recentContextLimit] — this is what goes into a fresh
  /// `InterventionContext.recentInterventions`, never the full log, so
  /// reasoning always sees a bounded amount of history regardless of how
  /// long the app's been used.
  List<InterventionHistoryEntry> get recent {
    if (_entries.length <= recentContextLimit) return List.unmodifiable(_entries);
    return List.unmodifiable(_entries.sublist(_entries.length - recentContextLimit));
  }
}
