import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_sync_repository.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Implementation of [ISyncRepository] coordinating synchronization
/// between local cache [ITaskRepository] and remote Supabase [ISyncRemoteDataSource].
class SyncRepositoryImpl implements ISyncRepository {
  SyncRepositoryImpl({
    required ITaskRepository local,
    required ISyncRemoteDataSource remote,
    required IAuthRepository auth,
  }) : _local = local,
       _remote = remote,
       _auth = auth;

  final ITaskRepository _local;
  final ISyncRemoteDataSource _remote;
  final IAuthRepository _auth;

  DateTime? _lastSyncedAt;

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  Future<Result<List<Task>>> syncWithCloud() async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) {
      AppLogger.info('syncWithCloud: user is null or guest, skipping cloud sync');
      return _local.getAll();
    }

    final accessToken = _auth.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.warning('syncWithCloud: access token missing');
      return const Error(
        AuthFailure('Отсутствует токен авторизации для синхронизации'),
      );
    }

    // 1. Fetch remote tasks from Supabase
    final cloudResult = await _remote.fetchTasks(
      userId: user.id,
      accessToken: accessToken,
    );

    if (cloudResult is Error<List<Task>>) {
      AppLogger.error('syncWithCloud: failed to fetch remote tasks: ${cloudResult.failure.message}');
      return cloudResult;
    }

    final cloudTasks = (cloudResult as Success<List<Task>>).data;

    // 2. Fetch local tasks
    final localResult = await _local.getAll();
    final localTasks = localResult is Success<List<Task>>
        ? localResult.data
        : <Task>[];

    // 3. Merge with Last-Write-Wins (LWW) conflict resolution
    final mergedMap = <int, Task>{};
    final tasksToUpload = <Task>[];

    final cloudMap = {for (final t in cloudTasks) t.id: t};
    final localMap = {for (final t in localTasks) t.id: t};

    for (final local in localTasks) {
      final remote = cloudMap[local.id];
      if (remote == null) {
        // Local only: needs upload to cloud
        final cleared = local.copyWith(isPendingSync: false);
        mergedMap[local.id] = cleared;
        tasksToUpload.add(cleared);
      } else {
        // Exists in both: compare timestamps
        final localTime =
            (local.updatedAt ?? local.createdAt).millisecondsSinceEpoch;
        final remoteTime =
            (remote.updatedAt ?? remote.createdAt).millisecondsSinceEpoch;

        if (local.isPendingSync || localTime >= remoteTime) {
          final cleared = local.copyWith(isPendingSync: false);
          mergedMap[local.id] = cleared;
          if (local.isPendingSync || localTime > remoteTime) {
            tasksToUpload.add(cleared);
          }
        } else {
          mergedMap[local.id] = remote;
        }
      }
    }

    // Process cloud tasks not present locally
    for (final remote in cloudTasks) {
      if (!localMap.containsKey(remote.id)) {
        mergedMap[remote.id] = remote;
      }
    }

    final mergedList = mergedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 4. Overwrite local repository with merged dataset
    for (final task in mergedList) {
      if (localMap.containsKey(task.id)) {
        await _local.update(task);
      } else {
        await _local.save(task);
      }
    }

    // 5. Upload pending changes to cloud
    if (tasksToUpload.isNotEmpty) {
      final uploadResult = await _remote.upsertAllTasks(
        tasks: tasksToUpload,
        userId: user.id,
        accessToken: accessToken,
      );

      if (uploadResult case Error(:final failure)) {
        AppLogger.warning('syncWithCloud: batch upload failed: ${failure.message}');
        // Mark local tasks as pending sync on network/server failure
        for (final failedTask in tasksToUpload) {
          await _local.update(failedTask.copyWith(isPendingSync: true));
        }
        return Error(failure);
      }
    }

    _lastSyncedAt = DateTime.now();
    AppLogger.info('syncWithCloud: sync completed successfully (${mergedList.length} tasks)');
    return Success(mergedList);
  }

  @override
  Future<Result<void>> pushTask(Task task) async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return const Success(null);

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return const Success(null);

    final result = await _remote.upsertTask(
      task: task,
      userId: user.id,
      accessToken: token,
    );

    if (result case Error(:final failure)) {
      AppLogger.warning(
        'pushTask: failed to push task ${task.id} to cloud: ${failure.message}. Marking isPendingSync = true',
      );
      // Mark task as pending sync in local store to avoid data loss
      await _local.update(task.copyWith(isPendingSync: true));
      return Error(failure);
    }

    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTask(int id) async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return const Success(null);

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return const Success(null);

    final result = await _remote.deleteTask(id: id, accessToken: token);
    if (result case Error(:final failure)) {
      AppLogger.warning('deleteTask: failed to delete task $id in cloud: ${failure.message}');
      return Error(failure);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteCompletedTasks() async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return const Success(null);

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return const Success(null);

    final result = await _remote.deleteCompletedTasks(
      userId: user.id,
      accessToken: token,
    );
    if (result case Error(:final failure)) {
      AppLogger.warning(
        'deleteCompletedTasks: failed in cloud: ${failure.message}',
      );
      return Error(failure);
    }
    return const Success(null);
  }
}
