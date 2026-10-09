import 'package:todo/features/tasks/data/models/sub_task_model.dart';
import 'package:todo/features/tasks/data/models/task_model.dart';
import 'package:todo/features/tasks/domain/entities/sub_task.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';

export 'package:todo/features/tasks/domain/entities/eisenhower_quadrant.dart';
export 'package:todo/features/tasks/domain/entities/recurrence_rule.dart';
export 'package:todo/features/tasks/domain/entities/sub_task.dart';
export 'package:todo/features/tasks/domain/entities/sync_status.dart';
export 'package:todo/features/tasks/domain/entities/task.dart';

/// Extension providing serialization on [Task] for backward compatibility.
/// The pure domain entity [Task] in `domain/entities/task.dart` remains
/// free from JSON dependencies, while callers can seamlessly use these helpers.
extension TaskSerializationExtension on Task {
  Map<String, dynamic> toMap() => TaskModel.fromEntity(this).toMap();
  String toJson() => TaskModel.fromEntity(this).toJson();
  Map<String, dynamic> toSupabaseMap(String userId) =>
      TaskModel.fromEntity(this).toSupabaseMap(userId);
}

extension SubTaskSerializationExtension on SubTask {
  Map<String, dynamic> toMap() => SubTaskModel.fromEntity(this).toMap();
}
