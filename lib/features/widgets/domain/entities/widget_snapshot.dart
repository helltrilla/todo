import 'package:todo/features/widgets/domain/entities/widget_pomodoro_state.dart';
import 'package:todo/features/widgets/domain/entities/widget_task_item.dart';

/// Pure Dart domain entity representing the full data payload synchronized to native widgets.
/// Contains ZERO Flutter imports and ZERO serialization methods.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.tasks,
    required this.pomodoro,
    required this.pendingCount,
    required this.completedCount,
    required this.updatedAt,
  });

  final List<WidgetTaskItem> tasks;
  final WidgetPomodoroState pomodoro;
  final int pendingCount;
  final int completedCount;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetSnapshot &&
          runtimeType == other.runtimeType &&
          pendingCount == other.pendingCount &&
          completedCount == other.completedCount &&
          pomodoro == other.pomodoro &&
          tasks.length == other.tasks.length;

  @override
  int get hashCode => Object.hash(
    tasks.length,
    pomodoro,
    pendingCount,
    completedCount,
    updatedAt,
  );
}
