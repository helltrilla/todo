import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Abstract interface for task and category persistence.
/// All failable operations return a functional [Result<T>].
abstract interface class ITaskRepository {
  Future<Result<List<Task>>> getAll();
  Future<Result<void>> save(Task task);
  Future<Result<void>> update(Task task);
  Future<Result<void>> delete(int id);
  Future<Result<void>> deleteCompleted();
  List<String> getCategories();
  Future<Result<void>> saveCategories(List<String> categories);
}
