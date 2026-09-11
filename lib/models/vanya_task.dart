import 'package:flutter/material.dart' show TimeOfDay;

/// A single planned task for a day. This is the ground truth Vanya's future
/// intervention system reads from to know what the user meant to be doing
/// — see `TaskService.getCurrentTask`/`getNextTask`.
class VanyaTask {
  const VanyaTask({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;

  /// Day this task is scheduled for. Only the year/month/day are
  /// meaningful — always normalized to midnight.
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The full start instant, combining [date] with [startTime].
  DateTime get startDateTime =>
      DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);

  /// The full end instant, combining [date] with [endTime].
  DateTime get endDateTime =>
      DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool isActiveAt(DateTime moment) =>
      !moment.isBefore(startDateTime) && moment.isBefore(endDateTime);

  VanyaTask copyWith({
    String? title,
    String? Function()? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return VanyaTask(
      id: id,
      title: title ?? this.title,
      description: description != null ? description() : this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VanyaTask.fromJson(Map<String, dynamic> json) {
    return VanyaTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
