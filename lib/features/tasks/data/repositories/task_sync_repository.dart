import 'dart:async';

import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Hybrid Offline-First repository implementing [ITaskRepository].
///
/// Ensures zero-latency UI interactions by saving to the local repository
/// immediately, then asynchronously syncing mutations to Supabase PostgREST
/// when the user has an active cloud session.
class TaskSyncRepository implements ITaskRepository {
  TaskSyncRepository({
    required ITaskRepository local,
    required ITaskRemoteDataSource remote,
    required IAuthRepository auth,
  })  : _local = local,
        _remote = remote,
        _auth = auth;

  final ITaskRepository _local;
  final ITaskRemoteDataSource _remote;
  final IAuthRepository _auth;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  Future<Result<List<Task>>> getAll() => _local.getAll();

  @override
  Future<Result<void>> save(Task task) async {
    final localResult = await _local.save(task);
    if (localResult is Success) {
      unawaited(_syncTaskToCloud(task));
    }
    return localResult;
  }

  @override
  Future<Result<void>> update(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    final localResult = await _local.update(updatedTask);
    if (localResult is Success) {
      unawaited(_syncTaskToCloud(updatedTask));
    }
    return localResult;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final localResult = await _local.delete(id);
    if (localResult is Success) {
      unawaited(_deleteTaskFromCloud(id));
    }
    return localResult;
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    final localResult = await _local.deleteCompleted();
    if (localResult is Success) {
      unawaited(_deleteCompletedFromCloud());
    }
    return localResult;
  }

  @override
  List<String> getCategories() => _local.getCategories();

  @override
  Future<Result<void>> saveCategories(List<String> categories) =>
      _local.saveCategories(categories);

  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() =>
      _local.getCategoryStyles();

  @override
  Future<Result<void>> saveCategoryStyles(
    Map<String, TaskCategoryStyle> styles,
  ) =>
      _local.saveCategoryStyles(styles);

  // ---------------------------------------------------------------------------
  // Cloud Synchronization (Bi-directional Merge)
  // ---------------------------------------------------------------------------

  /// Performs full two-way synchronization between local storage and Supabase.
  ///
  /// - Pulls remote tasks for current authenticated user.
  /// - Merges using Last-Write-Wins (LWW) conflict resolution.
  /// - Uploads local-only or newer local tasks to the cloud.
  /// - Updates local cache with the unified dataset.
  Future<Result<List<Task>>> syncWithCloud() async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) {
      // Local or guest mode does not sync to cloud, return local tasks
      return _local.getAll();
    }

    final accessToken = _auth.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return const Error(
        AuthFailure('Отсутствует токен авторизации для синхронизации'),
      );
    }

    // 1. Fetch from cloud
    final cloudResult = await _remote.fetchTasks(
      userId: user.id,
      accessToken: accessToken,
    );

    if (cloudResult is Error<List<Task>>) {
      return cloudResult;
    }

    final cloudTasks = (cloudResult as Success<List<Task>>).data;

    // 2. Fetch local tasks
    final localResult = await _local.getAll();
    final localTasks = localResult is Success<List<Task>>
        ? localResult.data
        : <Task>[];

    // 3. Merge: Index by task ID
    final mergedMap = <int, Task>{};
    final tasksToUpload = <Task>[];

    final cloudMap = {for (final t in cloudTasks) t.id: t};
    final localMap = {for (final t in localTasks) t.id: t};

    // Check all local tasks
    for (final local in localTasks) {
      final remote = cloudMap[local.id];
      if (remote == null) {
        // Local only: needs upload to cloud
        mergedMap[local.id] = local;
        tasksToUpload.add(local);
      } else {
        // Exists in both: compare updatedAt / createdAt
        final localTime = (local.updatedAt ?? local.createdAt).millisecondsSinceEpoch;
        final remoteTime = (remote.updatedAt ?? remote.createdAt).millisecondsSinceEpoch;

        if (localTime >= remoteTime) {
          mergedMap[local.id] = local;
          if (localTime > remoteTime) {
            tasksToUpload.add(local);
          }
        } else {
          mergedMap[local.id] = remote;
        }
      }
    }

    // Check cloud tasks not present locally
    for (final remote in cloudTasks) {
      if (!localMap.containsKey(remote.id)) {
        mergedMap[remote.id] = remote;
      }
    }

    final mergedList = mergedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 4. Overwrite local repository with full unified list
    for (final task in mergedList) {
      if (localMap.containsKey(task.id)) {
        await _local.update(task);
      } else {
        await _local.save(task);
      }
    }

    // 5. Upload pending changes to cloud
    if (tasksToUpload.isNotEmpty) {
      await _remote.upsertAllTasks(
        tasks: tasksToUpload,
        userId: user.id,
        accessToken: accessToken,
      );
    }

    _lastSyncedAt = DateTime.now();
    return Success(mergedList);
  }

  // ---------------------------------------------------------------------------
  // Internal background sync helpers
  // ---------------------------------------------------------------------------

  Future<void> _syncTaskToCloud(Task task) async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return;

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return;

    await _remote.upsertTask(
      task: task,
      userId: user.id,
      accessToken: token,
    );
  }

  Future<void> _deleteTaskFromCloud(int id) async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return;

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return;

    await _remote.deleteTask(id: id, accessToken: token);
  }

  Future<void> _deleteCompletedFromCloud() async {
    final user = _auth.getCurrentUser();
    if (user == null || user.isLocal) return;

    final token = _auth.getAccessToken();
    if (token == null || token.isEmpty) return;

    await _remote.deleteCompletedTasks(userId: user.id, accessToken: token);
  }
}
