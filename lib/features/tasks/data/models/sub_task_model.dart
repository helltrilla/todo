import 'package:todo/features/tasks/domain/entities/sub_task.dart';

/// Data Transfer Object (DTO) model for [SubTask].
/// Manages serialization, deserialization, and entity conversion.
class SubTaskModel extends SubTask {
  const SubTaskModel({
    required super.id,
    required super.title,
    super.isCompleted,
  });

  factory SubTaskModel.fromEntity(SubTask entity) {
    return SubTaskModel(
      id: entity.id,
      title: entity.title,
      isCompleted: entity.isCompleted,
    );
  }

  SubTask toEntity() {
    return SubTask(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubTaskModel.fromMap(Map<String, dynamic> map) {
    return SubTaskModel(
      id: (map['id'] as int?) ?? 0,
      title: (map['title'] as String?) ?? '',
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }
}
