import 'package:todo/features/tasks/domain/entities/eisenhower_quadrant.dart';
import 'package:todo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:todo/features/tasks/domain/entities/sub_task.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';

/// Immutable domain entity representing a single todo task.
/// Pure Dart entity adhering strictly to Clean Architecture:
/// free of JSON, DTO mappings, and framework dependencies.
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
  final bool isPendingSync;
  final bool? isUrgent;
  final bool? isImportant;

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
    this.isPendingSync = false,
    this.isUrgent,
    this.isImportant,
  });

  PriorityLevel get priority => PriorityLevel.fromIndex(priorityIndex);
  bool get hasPriority => priorityIndex != -1;
  bool get isRecurring => recurrence.isRepeating;
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  /// Effective urgency for Eisenhower quadrant calculation.
  /// Falls back to priority or due date heuristics if not explicitly set.
  bool get effectiveIsUrgent {
    if (isUrgent != null) return isUrgent!;
    if (priorityIndex == 0) return true;
    if (dueDate != null) {
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      if (dueDate!.isBefore(todayEnd) && (priorityIndex == 1 || priorityIndex == 2)) {
        return true;
      }
    }
    return false;
  }

  /// Effective importance for Eisenhower quadrant calculation.
  /// Falls back to priority heuristics if not explicitly set.
  bool get effectiveIsImportant {
    if (isImportant != null) return isImportant!;
    if (priorityIndex == 0 || priorityIndex == 1) return true;
    return false;
  }

  /// Eisenhower Matrix quadrant resolved from urgency and importance.
  EisenhowerQuadrant get quadrant => EisenhowerQuadrant.fromFlags(
        urgent: effectiveIsUrgent,
        important: effectiveIsImportant,
      );

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
    bool? isPendingSync,
    bool? isUrgent,
    bool? isImportant,
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
      isPendingSync: isPendingSync ?? this.isPendingSync,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, name: $name, value: $value, '
      'createdAt: $createdAt, dueDate: $dueDate, '
      'reminderOffsetMinutes: $reminderOffsetMinutes, '
      'priorityIndex: $priorityIndex, isCompleted: $isCompleted, '
      'isArchived: $isArchived, isPinned: $isPinned, category: $category, '
      'recurrence: ${recurrence.key}, pomodoros: $pomodoroCount, '
      'subtasks: ${subtasks.length}, isPendingSync: $isPendingSync, '
      'isUrgent: $isUrgent, isImportant: $isImportant)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
