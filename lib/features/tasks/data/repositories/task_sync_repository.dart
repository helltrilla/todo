import 'dart:async';

import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/data/repositories/sync_repository_impl.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_sync_repository.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Hybrid Offline-First repository implementing [ITaskRepository] and [ISyncRepository].
///
/// Ensures zero-latency UI interactions by saving to the local repository
/// immediately, then asynchronously syncing mutations to Supabase PostgREST
/// via [ISyncRepository].
class TaskSyncRepository implements ITaskRepository, ISyncRepository {
  TaskSyncRepository({
    required ITaskRepository local,
    required ISyncRemoteDataSource remote,
    required IAuthRepository auth,
  }) : _local = local,
       _syncRepository = SyncRepositoryImpl(
         local: local,
         remote: remote,
         auth: auth,
       );

  TaskSyncRepository.withSyncRepo({
    required ITaskRepository local,
    required ISyncRepository syncRepository,
  }) : _local = local,
       _syncRepository = syncRepository;

  final ITaskRepository _local;
  final ISyncRepository _syncRepository;

  ISyncRepository get syncRepository => _syncRepository;

  @override
  DateTime? get lastSyncedAt => _syncRepository.lastSyncedAt;

  @override
  Future<Result<List<Task>>> getAll() => _local.getAll();

  @override
  Future<Result<void>> save(Task task) async {
    final localResult = await _local.save(task);
    if (localResult is Success) {
      unawaited(_syncRepository.pushTask(task));
    }
    return localResult;
  }

  @override
  Future<Result<void>> update(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());
    final localResult = await _local.update(updatedTask);
    if (localResult is Success) {
      unawaited(_syncRepository.pushTask(updatedTask));
    }
    return localResult;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final localResult = await _local.delete(id);
    if (localResult is Success) {
      unawaited(_syncRepository.deleteTask(id));
    }
    return localResult;
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    final localResult = await _local.deleteCompleted();
    if (localResult is Success) {
      unawaited(_syncRepository.deleteCompletedTasks());
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
  ) => _local.saveCategoryStyles(styles);

  @override
  Future<Result<List<Task>>> syncWithCloud() => _syncRepository.syncWithCloud();

  @override
  Future<Result<void>> pushTask(Task task) => _syncRepository.pushTask(task);

  @override
  Future<Result<void>> deleteTask(int id) => _syncRepository.deleteTask(id);

  @override
  Future<Result<void>> deleteCompletedTasks() =>
      _syncRepository.deleteCompletedTasks();
}
