import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Atomic use case to update an existing task.
class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final ITaskRepository _repository;

  Future<Result<void>> call(Task task) => _repository.update(task);
}
