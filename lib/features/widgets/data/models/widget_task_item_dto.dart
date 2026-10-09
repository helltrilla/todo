import 'package:todo/features/widgets/domain/entities/widget_task_item.dart';

/// Data transfer object extending/mapping [WidgetTaskItem] with JSON serialization.
class WidgetTaskItemDto extends WidgetTaskItem {
  const WidgetTaskItemDto({
    required super.id,
    required super.title,
    required super.isCompleted,
    required super.priorityIndex,
    required super.category,
    super.dueDateLabel,
  });

  factory WidgetTaskItemDto.fromDomain(WidgetTaskItem item) {
    return WidgetTaskItemDto(
      id: item.id,
      title: item.title,
      isCompleted: item.isCompleted,
      priorityIndex: item.priorityIndex,
      category: item.category,
      dueDateLabel: item.dueDateLabel,
    );
  }

  factory WidgetTaskItemDto.fromMap(Map<String, dynamic> map) {
    return WidgetTaskItemDto(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String? ?? '',
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      priorityIndex: (map['priorityIndex'] as num?)?.toInt() ?? -1,
      category: map['category'] as String? ?? 'General',
      dueDateLabel: map['dueDateLabel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priorityIndex': priorityIndex,
      'category': category,
      if (dueDateLabel != null) 'dueDateLabel': dueDateLabel,
    };
  }
}
