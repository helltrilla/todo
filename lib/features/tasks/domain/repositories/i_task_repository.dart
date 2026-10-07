import 'package:todo/features/tasks/domain/models/task.dart';

/// Abstract interface for task persistence.
/// The domain layer knows nothing about SharedPreferences or any
/// storage implementation details.
abstract interface class ITaskRepository {
  Future<List<Task>> getAll();
  Future<void> save(Task task);
  Future<void> delete(int id);
}
