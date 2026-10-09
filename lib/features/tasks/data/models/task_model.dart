import 'dart:convert';

import 'package:todo/features/tasks/data/models/sub_task_model.dart';
import 'package:todo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:todo/features/tasks/domain/entities/sub_task.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';

/// Data Transfer Object (DTO) for [Task].
/// Responsible for JSON, Map, and Supabase PostgREST serialization.
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.name,
    required super.value,
    required super.createdAt,
    required super.priorityIndex,
    super.dueDate,
    super.completedAt,
    super.reminderOffsetMinutes,
    super.isCompleted,
    super.isArchived,
    super.isPinned,
    super.category,
    super.subtasks,
    super.recurrence,
    super.hasSpawnedNext,
    super.pomodoroCount,
    super.focusMinutes,
    super.updatedAt,
    super.isPendingSync,
    super.isUrgent,
    super.isImportant,
  });

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      name: task.name,
      value: task.value,
      createdAt: task.createdAt,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
      reminderOffsetMinutes: task.reminderOffsetMinutes,
      priorityIndex: task.priorityIndex,
      isCompleted: task.isCompleted,
      isArchived: task.isArchived,
      isPinned: task.isPinned,
      category: task.category,
      subtasks: task.subtasks,
      recurrence: task.recurrence,
      hasSpawnedNext: task.hasSpawnedNext,
      pomodoroCount: task.pomodoroCount,
      focusMinutes: task.focusMinutes,
      updatedAt: task.updatedAt,
      isPendingSync: task.isPendingSync,
      isUrgent: task.isUrgent,
      isImportant: task.isImportant,
    );
  }

  Task toEntity() {
    return Task(
      id: id,
      name: name,
      value: value,
      createdAt: createdAt,
      dueDate: dueDate,
      completedAt: completedAt,
      reminderOffsetMinutes: reminderOffsetMinutes,
      priorityIndex: priorityIndex,
      isCompleted: isCompleted,
      isArchived: isArchived,
      isPinned: isPinned,
      category: category,
      subtasks: subtasks,
      recurrence: recurrence,
      hasSpawnedNext: hasSpawnedNext,
      pomodoroCount: pomodoroCount,
      focusMinutes: focusMinutes,
      updatedAt: updatedAt,
      isPendingSync: isPendingSync,
      isUrgent: isUrgent,
      isImportant: isImportant,
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
      'subtasks': subtasks
          .map((s) => SubTaskModel.fromEntity(s).toMap())
          .toList(),
      'recurrence': recurrence.key,
      'hasSpawnedNext': hasSpawnedNext,
      'pomodoroCount': pomodoroCount,
      'focusMinutes': focusMinutes,
      'updatedAt': (updatedAt ?? createdAt).millisecondsSinceEpoch,
      'isPendingSync': isPendingSync,
      'isUrgent': isUrgent,
      'isImportant': isImportant,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'] as List<dynamic>?;
    final parsedSubtasks = rawSubtasks != null
        ? rawSubtasks
            .map((item) => SubTaskModel.fromMap(item as Map<String, dynamic>))
            .toList()
        : const <SubTask>[];

    return TaskModel(
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
      isPendingSync: (map['isPendingSync'] as bool?) ?? false,
      isUrgent: map['isUrgent'] as bool?,
      isImportant: map['isImportant'] as bool?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskModel.fromJson(String source) =>
      TaskModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Converts this model to a Supabase PostgREST row map.
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
      'subtasks': subtasks
          .map((s) => SubTaskModel.fromEntity(s).toMap())
          .toList(),
      'recurrence': recurrence.key,
      'has_spawned_next': hasSpawnedNext,
      'pomodoro_count': pomodoroCount,
      'focus_minutes': focusMinutes,
      'updated_at': (updatedAt ?? createdAt).millisecondsSinceEpoch,
      'is_urgent': isUrgent,
      'is_important': isImportant,
    };
  }

  /// Deserializes a [TaskModel] from a Supabase PostgREST row map.
  factory TaskModel.fromSupabaseMap(Map<String, dynamic> map) {
    final rawSubtasks = map['subtasks'] as List<dynamic>?;
    final parsedSubtasks = rawSubtasks != null
        ? rawSubtasks
            .map((item) => SubTaskModel.fromMap(item as Map<String, dynamic>))
            .toList()
        : const <SubTask>[];

    final createdMs = (map['created_at'] as num).toInt();
    final updatedMs = map['updated_at'] != null
        ? (map['updated_at'] as num).toInt()
        : createdMs;

    return TaskModel(
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
      isPendingSync: false,
      isUrgent: map['is_urgent'] as bool?,
      isImportant: map['is_important'] as bool?,
    );
  }
}
