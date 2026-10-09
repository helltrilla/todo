import 'dart:convert';
import 'package:todo/features/widgets/data/models/widget_pomodoro_state_dto.dart';
import 'package:todo/features/widgets/data/models/widget_task_item_dto.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';

/// Data transfer object extending/mapping [WidgetSnapshot] with JSON serialization.
class WidgetSnapshotDto extends WidgetSnapshot {
  const WidgetSnapshotDto({
    required super.tasks,
    required super.pomodoro,
    required super.pendingCount,
    required super.completedCount,
    required super.updatedAt,
  });

  factory WidgetSnapshotDto.fromDomain(WidgetSnapshot snapshot) {
    return WidgetSnapshotDto(
      tasks: snapshot.tasks,
      pomodoro: snapshot.pomodoro,
      pendingCount: snapshot.pendingCount,
      completedCount: snapshot.completedCount,
      updatedAt: snapshot.updatedAt,
    );
  }

  factory WidgetSnapshotDto.fromMap(Map<String, dynamic> map) {
    final rawTasks = map['tasks'] as List<dynamic>? ?? const [];
    final tasks = rawTasks
        .whereType<Map<String, dynamic>>()
        .map(WidgetTaskItemDto.fromMap)
        .toList();

    final pomodoroMap = map['pomodoro'] as Map<String, dynamic>? ?? const {};
    final pomodoro = WidgetPomodoroStateDto.fromMap(pomodoroMap);

    return WidgetSnapshotDto(
      tasks: tasks,
      pomodoro: pomodoro,
      pendingCount: (map['pendingCount'] as num?)?.toInt() ?? 0,
      completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['updatedAt'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tasks': tasks
          .map((t) => WidgetTaskItemDto.fromDomain(t).toMap())
          .toList(),
      'pomodoro': WidgetPomodoroStateDto.fromDomain(pomodoro).toMap(),
      'pendingCount': pendingCount,
      'completedCount': completedCount,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  String toJson() => jsonEncode(toMap());
}
