import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';

/// Supported recurrence rules for repeating tasks.
enum RecurrenceRule {
  none('none', 'Не повторять', 'Без повтора'),
  daily('daily', 'Каждый день', 'Ежедневно'),
  weekdays('weekdays', 'По будням (Пн–Пт)', 'По будням'),
  weekly('weekly', 'Каждую неделю', 'Еженедельно'),
  monthly('monthly', 'Каждый месяц', 'Ежемесячно');

  const RecurrenceRule(this.key, this.label, this.shortLabel);

  final String key;
  final String label;
  final String shortLabel;

  bool get isRepeating => this != RecurrenceRule.none;

  /// Computes the next occurrence [DateTime] strictly after [baseDate].
  DateTime nextDueDate(DateTime baseDate) {
    switch (this) {
      case RecurrenceRule.none:
        return baseDate;
      case RecurrenceRule.daily:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 1,
          baseDate.hour,
          baseDate.minute,
        );
      case RecurrenceRule.weekdays:
        var next = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 1,
          baseDate.hour,
          baseDate.minute,
        );
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = DateTime(
            next.year,
            next.month,
            next.day + 1,
            next.hour,
            next.minute,
          );
        }
        return next;
      case RecurrenceRule.weekly:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 7,
          baseDate.hour,
          baseDate.minute,
        );
      case RecurrenceRule.monthly:
        final nextMonthYear = baseDate.month == 12
            ? baseDate.year + 1
            : baseDate.year;
        final nextMonth = baseDate.month == 12 ? 1 : baseDate.month + 1;
        final maxDays = DateUtils.getDaysInMonth(nextMonthYear, nextMonth);
        final clampedDay = baseDate.day > maxDays ? maxDays : baseDate.day;
        return DateTime(
          nextMonthYear,
          nextMonth,
          clampedDay,
          baseDate.hour,
          baseDate.minute,
        );
    }
  }

  static RecurrenceRule fromKey(String? raw) {
    if (raw == null || raw.isEmpty) return RecurrenceRule.none;
    for (final rule in RecurrenceRule.values) {
      if (rule.key == raw) return rule;
    }
    return RecurrenceRule.none;
  }
}

/// Immutable domain model representing a single checklist item inside a [Task].
class SubTask {
  final int id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({int? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: (map['id'] as int?) ?? 0,
      title: (map['title'] as String?) ?? '',
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }
}

/// Immutable domain model representing a single todo task.
class Task {
  final int id;
  final String name;
  final String value;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int? reminderOffsetMinutes;
  final int priorityIndex;
  final bool isCompleted;
  final bool isArchived;
  final bool isPinned;
  final String category;
  final List<SubTask> subtasks;
  final RecurrenceRule recurrence;
  final bool hasSpawnedNext;
  final int pomodoroCount;
  final int focusMinutes;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.name,
    required this.value,
    required this.createdAt,
    required this.priorityIndex,
    this.dueDate,
    this.completedAt,
    this.reminderOffsetMinutes,
    this.isCompleted = false,
    this.isArchived = false,
    this.isPinned = false,
    this.category = 'Personal',
    this.subtasks = const [],
    this.recurrence = RecurrenceRule.none,
    this.hasSpawnedNext = false,
    this.pomodoroCount = 0,
    this.focusMinutes = 0,
    this.updatedAt,
  });

  PriorityLevel get priority => PriorityLevel.fromIndex(priorityIndex);
  bool get hasPriority => priorityIndex != -1;
  bool get isRecurring => recurrence.isRepeating;
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  /// Human-readable label for the configured reminder offset (e.g. "За 15 мин").
  String? get reminderLabel {
    if (dueDate == null) return null;
    if (reminderOffsetMinutes == null || reminderOffsetMinutes! <= 0) {
      return 'В момент';
    }
    return formatReminderOffset(reminderOffsetMinutes!);
  }

  /// Formats [minutes] into a Russian reminder label.
  static String formatReminderOffset(int minutes) {
    if (minutes <= 0) return 'В момент задачи';
    if (minutes < 60) return 'За $minutes мин';
    if (minutes == 60) return 'За 1 час';
    if (minutes == 120) return 'За 2 часа';
    if (minutes == 1440) return 'За 1 день';
    if (minutes % 60 == 0) return 'За ${minutes ~/ 60} ч';
    return 'За $minutes мин';
  }

  Task copyWith({
    int? id,
    String? name,
    String? value,
    DateTime? createdAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? reminderOffsetMinutes,
    bool clearReminder = false,
    int? priorityIndex,
    bool? isCompleted,
    bool? isArchived,
    bool? isPinned,
    String? category,
    List<SubTask>? subtasks,
    RecurrenceRule? recurrence,
    bool? hasSpawnedNext,
    int? pomodoroCount,
    int? focusMinutes,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      reminderOffsetMinutes: clearDueDate || clearReminder
          ? null
          : (reminderOffsetMinutes ?? this.reminderOffsetMinutes),
      priorityIndex: priorityIndex ?? this.priorityIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      recurrence: recurrence ?? this.recurrence,
      hasSpawnedNext: hasSpawnedNext ?? this.hasSpawnedNext,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      updatedAt: updatedAt ?? this.updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'value': value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'priorityIndex': priorityIndex,
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'category': category,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'recurrence': recurrence.key,
      'hasSpawnedNext': hasSpawnedNext,
      'pomodoroCount': pomodoroCount,
      'focusMinutes': focusMinutes,
      'updatedAt': (updatedAt ?? createdAt).millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'] as List<dynamic>?;
    final parsedSubtasks = rawSubtasks != null
        ? rawSubtasks
              .map((item) => SubTask.fromMap(item as Map<String, dynamic>))
              .toList()
        : const <SubTask>[];

    return Task(
      id: map['id'] as int,
      name: map['name'] as String,
      value: (map['value'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      reminderOffsetMinutes: map['reminderOffsetMinutes'] as int?,
      priorityIndex: (map['priorityIndex'] as int?) ?? -1,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      isArchived: (map['isArchived'] as bool?) ?? false,
      isPinned: (map['isPinned'] as bool?) ?? false,
      category: (map['category'] as String?) ?? 'Personal',
      subtasks: parsedSubtasks,
      recurrence: RecurrenceRule.fromKey(map['recurrence'] as String?),
      hasSpawnedNext: (map['hasSpawnedNext'] as bool?) ?? false,
      pomodoroCount: (map['pomodoroCount'] as int?) ?? 0,
      focusMinutes: (map['focusMinutes'] as int?) ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  /// Converts this [Task] to a Supabase PostgREST row map.
  Map<String, dynamic> toSupabaseMap(String userId) {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'value': value,
      'created_at': createdAt.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'reminder_offset_minutes': reminderOffsetMinutes,
      'priority_index': priorityIndex,
      'is_completed': isCompleted,
      'is_archived': isArchived,
      'is_pinned': isPinned,
      'category': category,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'recurrence': recurrence.key,
      'has_spawned_next': hasSpawnedNext,
      'pomodoro_count': pomodoroCount,
      'focus_minutes': focusMinutes,
      'updated_at': (updatedAt ?? createdAt).millisecondsSinceEpoch,
    };
  }

  /// Deserializes a [Task] from a Supabase PostgREST row map.
  factory Task.fromSupabaseMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'] as List<dynamic>?;
    final parsedSubtasks = rawSubtasks != null
        ? rawSubtasks
              .map((item) => SubTask.fromMap(item as Map<String, dynamic>))
              .toList()
        : const <SubTask>[];

    final createdMs = (map['created_at'] as num).toInt();
    final updatedMs = map['updated_at'] != null
        ? (map['updated_at'] as num).toInt()
        : createdMs;

    return Task(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String,
      value: (map['value'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedMs),
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['due_date'] as num).toInt(),
            )
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['completed_at'] as num).toInt(),
            )
          : null,
      reminderOffsetMinutes: map['reminder_offset_minutes'] as int?,
      priorityIndex: (map['priority_index'] as int?) ?? -1,
      isCompleted: (map['is_completed'] as bool?) ?? false,
      isArchived: (map['is_archived'] as bool?) ?? false,
      isPinned: (map['is_pinned'] as bool?) ?? false,
      category: (map['category'] as String?) ?? 'Personal',
      subtasks: parsedSubtasks,
      recurrence: RecurrenceRule.fromKey(map['recurrence'] as String?),
      hasSpawnedNext: (map['has_spawned_next'] as bool?) ?? false,
      pomodoroCount: (map['pomodoro_count'] as int?) ?? 0,
      focusMinutes: (map['focus_minutes'] as int?) ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Task(id: $id, name: $name, value: $value, '
      'createdAt: $createdAt, dueDate: $dueDate, '
      'reminderOffsetMinutes: $reminderOffsetMinutes, '
      'priorityIndex: $priorityIndex, isCompleted: $isCompleted, '
      'isArchived: $isArchived, isPinned: $isPinned, category: $category, '
      'recurrence: ${recurrence.key}, pomodoros: $pomodoroCount, '
      'subtasks: ${subtasks.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
