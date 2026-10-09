import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/data/models/sub_task_model.dart';
import 'package:todo/features/tasks/data/models/task_model.dart';
import 'package:todo/features/tasks/data/repositories/sync_repository_impl.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/domain/entities/recurrence_rule.dart';
import 'package:todo/features/tasks/domain/entities/sub_task.dart';
import 'package:todo/features/tasks/domain/entities/sync_status.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:todo/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:todo/features/tasks/domain/usecases/get_tasks_use_case.dart';
import 'package:todo/features/tasks/domain/usecases/sync_tasks_use_case.dart';
import 'package:todo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:todo/features/tasks/presentation/controllers/pomodoro_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/sync_controller.dart';
class _FakeAuthRepository implements IAuthRepository {
  AppUser? user;
  String? token;

  @override
  AppUser? getCurrentUser() => user;

  @override
  String? getAccessToken() => token;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteDataSource implements ISyncRemoteDataSource {
  List<Task> remoteTasks = [];
  bool shouldFailFetch = false;
  bool shouldFailUpsert = false;
  bool shouldFailUpsertAll = false;

  @override
  Future<Result<List<Task>>> fetchTasks({
    required String userId,
    required String accessToken,
  }) async {
    if (shouldFailFetch) {
      return const Error(NetworkFailure('Fetch network error'));
    }
    return Success(List.from(remoteTasks));
  }

  @override
  Future<Result<Task>> upsertTask({
    required Task task,
    required String userId,
    required String accessToken,
  }) async {
    if (shouldFailUpsert) {
      return const Error(NetworkFailure('Upsert failed'));
    }
    remoteTasks.removeWhere((t) => t.id == task.id);
    remoteTasks.add(task);
    return Success(task);
  }

  @override
  Future<Result<void>> upsertAllTasks({
    required List<Task> tasks,
    required String userId,
    required String accessToken,
  }) async {
    if (shouldFailUpsertAll) {
      return const Error(NetworkFailure('Batch upload failed'));
    }
    for (final task in tasks) {
      remoteTasks.removeWhere((t) => t.id == task.id);
      remoteTasks.add(task);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTask({
    required int id,
    required String accessToken,
  }) async {
    remoteTasks.removeWhere((t) => t.id == id);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteCompletedTasks({
    required String userId,
    required String accessToken,
  }) async {
    remoteTasks.removeWhere((t) => t.isCompleted);
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clean Architecture - TaskModel & SubTaskModel DTOs', () {
    test('TaskModel properly converts to and from domain Entity', () {
      final now = DateTime(2026, 10, 9, 10, 0);
      const subtask = SubTask(id: 1, title: 'Item 1', isCompleted: true);
      final entity = Task(
        id: 100,
        name: 'Clean Arch Task',
        value: 'Testing DTO',
        createdAt: now,
        priorityIndex: 1,
        dueDate: now.add(const Duration(days: 1)),
        category: 'Work',
        subtasks: const [subtask],
        recurrence: RecurrenceRule.daily,
        isPendingSync: true,
      );

      final model = TaskModel.fromEntity(entity);
      expect(model.id, 100);
      expect(model.name, 'Clean Arch Task');
      expect(model.priority, PriorityLevel.p2);
      expect(model.isPendingSync, isTrue);

      final restoredEntity = model.toEntity();
      expect(restoredEntity, equals(entity));
      expect(restoredEntity.isPendingSync, isTrue);
    });

    test('SubTaskModel converts to Map and back', () {
      const subtask = SubTask(id: 42, title: 'Write tests', isCompleted: true);
      final model = SubTaskModel.fromEntity(subtask);
      final map = model.toMap();

      expect(map['id'], 42);
      expect(map['title'], 'Write tests');
      expect(map['isCompleted'], isTrue);

      final restored = SubTaskModel.fromMap(map);
      expect(restored.id, 42);
      expect(restored.title, 'Write tests');
      expect(restored.isCompleted, isTrue);
    });

    test('Pure RecurrenceRule computes nextDueDate without Flutter material dependencies', () {
      final base = DateTime(2026, 1, 31, 14, 0); // End of January
      final dailyNext = RecurrenceRule.daily.nextDueDate(base);
      expect(dailyNext, DateTime(2026, 2, 1, 14, 0));

      final monthlyNext = RecurrenceRule.monthly.nextDueDate(base);
      // Feb 2026 has 28 days, clamped to 28
      expect(monthlyNext, DateTime(2026, 2, 28, 14, 0));
    });
  });

  group('Clean Architecture - Task Use Cases', () {
    late SharedPreferences prefs;
    late TaskLocalRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = TaskLocalRepository(prefs);
    });

    test('CreateTaskUseCase and GetTasksUseCase work end-to-end', () async {
      final createUseCase = CreateTaskUseCase(repository);
      final getUseCase = GetTasksUseCase(repository);

      final task = Task(
        id: 1,
        name: 'Use case task',
        value: 'Created via use case',
        createdAt: DateTime.now(),
        priorityIndex: 0,
      );

      final createResult = await createUseCase(task);
      expect(createResult, isA<Success<void>>());

      final getResult = await getUseCase();
      expect(getResult, isA<Success<List<Task>>>());
      final tasks = (getResult as Success<List<Task>>).data;
      expect(tasks.length, 1);
      expect(tasks.first.name, 'Use case task');
    });

    test('UpdateTaskUseCase and DeleteTaskUseCase modify store', () async {
      final createUseCase = CreateTaskUseCase(repository);
      final updateUseCase = UpdateTaskUseCase(repository);
      final deleteUseCase = DeleteTaskUseCase(repository);
      final getUseCase = GetTasksUseCase(repository);

      final task = Task(
        id: 5,
        name: 'Initial Name',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: -1,
      );
      await createUseCase(task);

      final updatedTask = task.copyWith(name: 'Updated Name', isCompleted: true);
      final updateResult = await updateUseCase(updatedTask);
      expect(updateResult, isA<Success<void>>());

      var fetched = (await getUseCase() as Success<List<Task>>).data;
      expect(fetched.first.name, 'Updated Name');
      expect(fetched.first.isCompleted, isTrue);

      final deleteResult = await deleteUseCase(5);
      expect(deleteResult, isA<Success<void>>());

      fetched = (await getUseCase() as Success<List<Task>>).data;
      expect(fetched, isEmpty);
    });
  });

  group('Clean Architecture - SyncRepositoryImpl & Offline-First Fault Tolerance', () {
    late SharedPreferences prefs;
    late TaskLocalRepository localRepo;
    late _FakeRemoteDataSource remoteDataSource;
    late _FakeAuthRepository authRepo;
    late SyncRepositoryImpl syncRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localRepo = TaskLocalRepository(prefs);
      remoteDataSource = _FakeRemoteDataSource();
      authRepo = _FakeAuthRepository();
      authRepo.user = const AppUser(
        id: 'user-cloud-1',
        name: 'Cloud User',
        email: 'user@cloud.com',
        isLocal: false,
      );
      authRepo.token = 'valid-token';

      syncRepo = SyncRepositoryImpl(
        local: localRepo,
        remote: remoteDataSource,
        auth: authRepo,
      );
    });

    test('Marks task isPendingSync = true on network push failure instead of losing data', () async {
      remoteDataSource.shouldFailUpsert = true;

      final task = Task(
        id: 10,
        name: 'Network fail task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1,
      );
      await localRepo.save(task);

      final pushResult = await syncRepo.pushTask(task);
      expect(pushResult, isA<Error<void>>());

      // Task in local repository must now have isPendingSync == true
      final localFetch = (await localRepo.getAll() as Success<List<Task>>).data;
      expect(localFetch.first.id, 10);
      expect(localFetch.first.isPendingSync, isTrue);
    });

    test('Clears isPendingSync when two-way sync completes successfully', () async {
      final task = Task(
        id: 20,
        name: 'Pending sync task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
        isPendingSync: true,
      );
      await localRepo.save(task);

      final syncResult = await syncRepo.syncWithCloud();
      expect(syncResult, isA<Success<List<Task>>>());

      // Remote data source now has the task
      expect(remoteDataSource.remoteTasks.any((t) => t.id == 20), isTrue);

      // Local task should have isPendingSync cleared
      final localFetch = (await localRepo.getAll() as Success<List<Task>>).data;
      expect(localFetch.first.isPendingSync, isFalse);
    });
  });

  group('PomodoroController', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'focus_selected_minutes': 25});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initializes with stored minutes and default state', () {
      final controller = PomodoroController(prefs: prefs);
      expect(controller.selectedMinutes, 25);
      expect(controller.remainingSeconds, 25 * 60);
      expect(controller.isRunning, isFalse);
      expect(controller.progress, 1.0);
      expect(controller.formattedTime, '25:00');
      controller.dispose();
    });

    test('selectPreset updates duration and resets timer', () async {
      final controller = PomodoroController(prefs: prefs);
      await controller.selectPreset(45);

      expect(controller.selectedMinutes, 45);
      expect(controller.remainingSeconds, 45 * 60);
      expect(controller.isRunning, isFalse);
      expect(controller.formattedTime, '45:00');
      expect(prefs.getInt('focus_selected_minutes'), 45);
      controller.dispose();
    });

    test('toggleTimer starts and pauses countdown', () {
      final controller = PomodoroController(prefs: prefs);
      controller.toggleTimer();
      expect(controller.isRunning, isTrue);

      controller.toggleTimer();
      expect(controller.isRunning, isFalse);

      controller.reset();
      expect(controller.remainingSeconds, 25 * 60);
      controller.dispose();
    });

    test('focus task selection updates focusedTaskId and focusedTaskName', () {
      final controller = PomodoroController(prefs: prefs);
      controller.setFocusedTaskId(99, taskName: 'Deep Work');
      expect(controller.focusedTaskId, 99);
      expect(controller.focusedTaskName, 'Deep Work');

      controller.setFocusedTaskId(null);
      expect(controller.focusedTaskId, isNull);
      expect(controller.focusedTaskName, isNull);
      controller.dispose();
    });
  });

  group('SyncController', () {
    late _FakeRemoteDataSource remoteDataSource;
    late _FakeAuthRepository authRepo;
    late TaskLocalRepository localRepo;
    late SyncRepositoryImpl syncRepo;
    late SyncTasksUseCase syncUseCase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localRepo = TaskLocalRepository(prefs);
      remoteDataSource = _FakeRemoteDataSource();
      authRepo = _FakeAuthRepository();
      authRepo.user = const AppUser(
        id: 'user-sync-test',
        name: 'Tester',
        isLocal: false,
      );
      authRepo.token = 'jwt-token';
      syncRepo = SyncRepositoryImpl(
        local: localRepo,
        remote: remoteDataSource,
        auth: authRepo,
      );
      syncUseCase = SyncTasksUseCase(syncRepo);
    });

    test('transitions through idle -> syncing -> success', () async {
      final controller = SyncController(syncUseCase: syncUseCase);
      expect(controller.status, SyncStatus.idle);
      expect(controller.isSyncing, isFalse);
      expect(controller.hasSyncError, isFalse);

      final ok = await controller.syncWithCloud();
      expect(ok, isTrue);
      expect(controller.status, SyncStatus.success);
      expect(controller.isSuccess, isTrue);
      expect(controller.lastSyncedAt, isNotNull);
      expect(controller.syncError, isNull);
      controller.dispose();
    });

    test('records error when cloud fetch fails', () async {
      remoteDataSource.shouldFailFetch = true;
      final controller = SyncController(syncUseCase: syncUseCase);

      final ok = await controller.syncWithCloud();
      expect(ok, isFalse);
      expect(controller.status, SyncStatus.error);
      expect(controller.hasSyncError, isTrue);
      expect(controller.syncError, contains('Fetch network error'));

      controller.clearError();
      expect(controller.status, SyncStatus.idle);
      expect(controller.syncError, isNull);
      controller.dispose();
    });
  });
}
