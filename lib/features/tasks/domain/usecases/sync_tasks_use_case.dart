import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_sync_repository.dart';

/// Atomic use case to perform two-way synchronization of tasks with the cloud.
class SyncTasksUseCase {
  const SyncTasksUseCase(this._repository);

  final ISyncRepository _repository;

  ISyncRepository get repository => _repository;

  Future<Result<List<Task>>> call() => _repository.syncWithCloud();
}
