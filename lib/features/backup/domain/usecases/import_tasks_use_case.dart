import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/domain/repositories/i_backup_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Atomic use case that imports and parses tasks from JSON backup content.
class ImportTasksUseCase {
  const ImportTasksUseCase(this._repository);

  final IBackupRepository _repository;

  Future<Result<List<Task>>> call(String jsonContent) {
    if (jsonContent.trim().isEmpty) {
      return Future.value(const Error(ServerFailure('Файл бэкапа пуст')));
    }
    return _repository.importTasksFromJson(jsonContent);
  }
}
