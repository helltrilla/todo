import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Pure Dart abstract repository contract for backup, serialization, and export.
abstract interface class IBackupRepository {
  /// Serializes [tasks] in an asynchronous Isolate into target [format].
  Future<Result<ExportResult>> exportTasks({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  });

  /// Deserializes JSON backup content in an Isolate and returns validated tasks.
  Future<Result<List<Task>>> importTasksFromJson(String jsonContent);

  /// Shares or saves [exportResult] using native system share sheet.
  Future<Result<void>> shareExport(ExportResult exportResult);
}
