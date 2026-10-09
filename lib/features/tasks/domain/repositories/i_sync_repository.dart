import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';

/// Domain contract for cloud synchronization of tasks.
/// Encapsulates all interactions between local cache and remote storage.
abstract interface class ISyncRepository {
  /// Performs full bi-directional synchronization between local storage and cloud.
  Future<Result<List<Task>>> syncWithCloud();

  /// Pushes a single task to cloud storage.
  Future<Result<void>> pushTask(Task task);

  /// Deletes a single task from cloud storage by its ID.
  Future<Result<void>> deleteTask(int id);

  /// Deletes all completed tasks from cloud storage.
  Future<Result<void>> deleteCompletedTasks();

  /// Timestamp of the most recent successful sync.
  DateTime? get lastSyncedAt;
}
