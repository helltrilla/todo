import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Atomic use case to create and persist a new task.
class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final ITaskRepository _repository;

  Future<Result<void>> call(Task task) => _repository.save(task);
}
