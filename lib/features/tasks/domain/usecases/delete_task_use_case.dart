import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Atomic use case to delete a task by its ID.
class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);

  final ITaskRepository _repository;

  Future<Result<void>> call(int id) => _repository.delete(id);
}
