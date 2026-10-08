import 'dart:convert';

import 'package:todo/features/tasks/domain/models/priority_level.dart';

/// Immutable domain model representing a single todo task.
class Task {
  final int id;
  final String name;
  final String value;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int priorityIndex;
  final bool isCompleted;
  final String category;

  const Task({
    required this.id,
    required this.name,
    required this.value,
    required this.createdAt,
    required this.priorityIndex,
    this.dueDate,
    this.isCompleted = false,
    this.category = 'Personal',
  });

  PriorityLevel get priority => PriorityLevel.fromIndex(priorityIndex);
  bool get hasPriority => priorityIndex != -1;

  Task copyWith({
    int? id,
    String? name,
    String? value,
    DateTime? createdAt,
    DateTime? dueDate,
    int? priorityIndex,
    bool? isCompleted,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
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
      'category': category,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
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
      category: (map['category'] as String?) ?? 'Personal',
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Task(id: $id, name: $name, value: $value, '
      'createdAt: $createdAt, dueDate: $dueDate, '
      'priorityIndex: $priorityIndex, isCompleted: $isCompleted, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
