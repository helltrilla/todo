import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/backup/domain/repositories/i_backup_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Atomic use case that exports tasks collection to JSON, CSV, or Markdown.
class ExportTasksUseCase {
  const ExportTasksUseCase(this._repository);

  final IBackupRepository _repository;

  Future<Result<ExportResult>> call({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  }) {
    return _repository.exportTasks(
      tasks: tasks,
      format: format,
      categories: categories,
    );
  }
}
