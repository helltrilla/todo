import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Atomic use case to retrieve all persisted tasks.
class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final ITaskRepository _repository;

  Future<Result<List<Task>>> call() => _repository.getAll();
}
