import 'dart:convert';

import 'package:todo/features/tasks/domain/models/priority_level.dart';

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
  final int priorityIndex;
  final bool isCompleted;
  final bool isArchived;
  final String category;
  final List<SubTask> subtasks;

  const Task({
    required this.id,
    required this.name,
    required this.value,
    required this.createdAt,
    required this.priorityIndex,
    this.dueDate,
    this.isCompleted = false,
    this.isArchived = false,
    this.category = 'Personal',
    this.subtasks = const [],
  });

  PriorityLevel get priority => PriorityLevel.fromIndex(priorityIndex);
  bool get hasPriority => priorityIndex != -1;
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  Task copyWith({
    int? id,
    String? name,
    String? value,
    DateTime? createdAt,
    DateTime? dueDate,
    int? priorityIndex,
    bool? isCompleted,
    bool? isArchived,
    String? category,
    List<SubTask>? subtasks,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'value': value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priorityIndex': priorityIndex,
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'category': category,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
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
      priorityIndex: (map['priorityIndex'] as int?) ?? -1,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      isArchived: (map['isArchived'] as bool?) ?? false,
      category: (map['category'] as String?) ?? 'Personal',
      subtasks: parsedSubtasks,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Task(id: $id, name: $name, value: $value, '
      'createdAt: $createdAt, dueDate: $dueDate, '
      'priorityIndex: $priorityIndex, isCompleted: $isCompleted, '
      'isArchived: $isArchived, category: $category, '
      'subtasks: ${subtasks.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
