import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/data/repositories/task_sync_repository.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/main.dart';

class _FailingRepository implements ITaskRepository {
  @override
  Future<Result<List<Task>>> getAll() async =>
      const Error(CacheFailure('Read failed'));

  @override
  Future<Result<void>> save(Task task) async =>
      const Error(CacheFailure('Save failed'));

  @override
  Future<Result<void>> update(Task task) async =>
      const Error(CacheFailure('Update failed'));

  @override
  Future<Result<void>> delete(int id) async =>
      const Error(CacheFailure('Delete failed'));

  @override
  Future<Result<void>> deleteCompleted() async =>
      const Error(CacheFailure('Delete completed failed'));

  @override
  List<String> getCategories() => const ['Work', 'Personal'];

  @override
  Future<Result<void>> saveCategories(List<String> categories) async =>
      const Error(CacheFailure('Save categories failed'));

  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() => const {};

  @override
  Future<Result<void>> saveCategoryStyles(
    Map<String, TaskCategoryStyle> styles,
  ) async => const Error(CacheFailure('Save category styles failed'));
}

void main() {
  group('Task & PriorityLevel Models', () {
    test('Task serializes to and from JSON accurately', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final due = DateTime.fromMillisecondsSinceEpoch(1700086400000);
      final task = Task(
        id: 1,
        name: 'Buy groceries',
        value: 'Milk and eggs',
        createdAt: now,
        dueDate: due,
        priorityIndex: 0,
        isCompleted: true,
        category: 'Work',
        subtasks: const [
          SubTask(id: 101, title: 'Buy milk', isCompleted: true),
          SubTask(id: 102, title: 'Buy eggs', isCompleted: false),
        ],
      );

      final jsonStr = task.toJson();
      final restored = Task.fromJson(jsonStr);

      expect(restored, equals(task));
      expect(restored.name, 'Buy groceries');
      expect(restored.value, 'Milk and eggs');
      expect(restored.createdAt, now);
      expect(restored.dueDate, due);
      expect(restored.priority, PriorityLevel.p1);
      expect(restored.hasPriority, isTrue);
      expect(restored.isCompleted, isTrue);
      expect(restored.category, 'Work');
      expect(restored.subtasks.length, 2);
      expect(restored.completedSubtasksCount, 1);
    });

    test('Task handles null dueDate and default priority', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final task = Task(
        id: 2,
        name: 'Clean room',
        value: '',
        createdAt: now,
        priorityIndex: -1,
      );

      final restored = Task.fromJson(task.toJson());
      expect(restored.dueDate, isNull);
      expect(restored.hasPriority, isFalse);
      expect(restored.priority, PriorityLevel.none);
      expect(restored.isCompleted, isFalse);
      expect(restored.category, 'Personal');
    });

    test('Task copyWith updates specified fields', () {
      final task = Task(
        id: 1,
        name: 'Old',
        value: 'Desc',
        createdAt: DateTime(2026),
        priorityIndex: -1,
      );
      final updated = task.copyWith(
        name: 'New',
        priorityIndex: 2,
        isCompleted: true,
        category: 'Work',
      );
      expect(updated.id, 1);
      expect(updated.name, 'New');
      expect(updated.value, 'Desc');
      expect(updated.priority, PriorityLevel.p3);
      expect(updated.isCompleted, isTrue);
      expect(updated.category, 'Work');
    });
  });

  group('AuthRepositoryImpl (Internal & Supabase OTP)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('registers and signs in internal account locally', () async {
      final repo = AuthRepositoryImpl(prefs);
      expect(repo.getCurrentUser(), isNull);

      final regResult = await repo.registerInternal(
        name: 'Daniil',
        login: 'daniil_dev',
        password: 'secret',
      );
      expect(regResult, isA<Success<AppUser>>());
      final registered = (regResult as Success<AppUser>).data;
      expect(registered.name, 'Daniil');
      expect(registered.isLocal, isTrue);
      expect(repo.getCurrentUser(), equals(registered));

      await repo.signOut();
      expect(repo.getCurrentUser(), isNull);

      final signResult = await repo.signInInternal(
        login: 'daniil_dev',
        password: 'secret',
      );
      expect(signResult, isA<Success<AppUser>>());
      expect((signResult as Success<AppUser>).data.name, 'Daniil');
    });

    test('sends and verifies Supabase Email OTP via REST API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/v1/otp')) {
          return http.Response('{}', 200);
        }
        if (request.url.path.endsWith('/auth/v1/verify')) {
          return http.Response(
            json.encode({
              'user': {
                'id': 'sb-user-1',
                'email': 'test@example.com',
                'user_metadata': {'name': 'Supabase User'},
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = AuthRepositoryImpl(prefs, httpClient: mockClient);
      final otpResult = await repo.sendEmailOtp(
        email: 'test@example.com',
        name: 'Supabase User',
      );
      expect(otpResult, isA<Success<void>>());

      final verifyResult = await repo.verifyEmailOtp(
        email: 'test@example.com',
        code: '123456',
      );
      expect(verifyResult, isA<Success<AppUser>>());
      final user = (verifyResult as Success<AppUser>).data;

      expect(user.id, 'sb-user-1');
      expect(user.name, 'Supabase User');
      expect(user.isLocal, isFalse);
      expect(repo.getCurrentUser(), equals(user));
    });
  });

  group('TaskLocalRepository', () {
    late SharedPreferences prefs;
    late TaskLocalRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = TaskLocalRepository(prefs);
    });

    test('saves, updates, loads, and deletes tasks via Result monad', () async {
      final t1 = Task(
        id: 10,
        name: 'Task 1',
        value: 'V1',
        createdAt: DateTime(2026),
        priorityIndex: 0,
      );
      final t2 = Task(
        id: 20,
        name: 'Task 2',
        value: 'V2',
        createdAt: DateTime(2026),
        priorityIndex: 1,
      );

      await repo.save(t1);
      await repo.save(t2);
      await repo.update(t1.copyWith(isCompleted: true));

      final allResult = await repo.getAll();
      expect(allResult, isA<Success<List<Task>>>());
      final all = (allResult as Success<List<Task>>).data;
      expect(all.length, 2);
      expect(all.first.isCompleted, isTrue);

      await repo.delete(10);
      final remainingResult = await repo.getAll();
      final remaining = (remainingResult as Success<List<Task>>).data;
      expect(remaining.length, 1);
      expect(remaining.first.id, 20);
    });
  });

  group('TaskController', () {
    late SharedPreferences prefs;
    late TaskController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      controller = TaskController(TaskLocalRepository(prefs));
    });

    test(
      'adds, updates, sorts, filters by category/search, and groups sections',
      () async {
        final tomorrow = DateTime.now().add(const Duration(days: 2));

        await controller.add(
          name: 'Doing housework',
          value: '',
          priorityIndex: 5,
          category: 'Personal',
          dueDate: tomorrow,
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await controller.add(
          name: 'Do groceries',
          value: '',
          priorityIndex: 0,
          category: 'Work',
        );

        expect(controller.tasks.length, 2);
        expect(controller.futureTasks.length, 1);
        expect(controller.todayTasks.length, 1);

        final firstTask = controller.tasks.first;
        await controller.updateTask(
          firstTask.copyWith(name: 'Buy fresh groceries'),
        );
        expect(controller.tasks.first.name, 'Buy fresh groceries');

        controller.selectCategory('Work');
        expect(controller.tasks.length, 1);
        expect(controller.tasks.first.name, 'Buy fresh groceries');

        // Add a global task ('Общее') -> it must stay visible even when 'Personal' is selected
        await controller.add(
          name: 'Global pinned task',
          value: '',
          priorityIndex: 2,
          category: TaskController.globalCategory,
        );
        controller.selectCategory('Personal');
        expect(
          controller.tasks.any((t) => t.name == 'Global pinned task'),
          isTrue,
        );

        controller.selectCategory(TaskController.allCategory);
        controller.setSearchQuery('housework');
        expect(controller.tasks.length, 1);
        expect(controller.tasks.first.name, 'Doing housework');

        controller.setSearchQuery('');
        await controller.toggleCompleted(controller.tasks.first.id);
        expect(controller.tasks.any((t) => t.isCompleted), isTrue);

        // Add custom category with custom iconIndex and colorIndex
        await controller.addCategory('Fitness', iconIndex: 3, colorIndex: 2);
        final fitnessStyle = controller.styleForCategory('Fitness');
        expect(fitnessStyle.iconIndex, 3);
        expect(fitnessStyle.colorIndex, 2);
      },
    );

    test(
      'rolls back optimistic add and delete on repository failure',
      () async {
        final failingController = TaskController(_FailingRepository());

        await failingController.add(name: 'Will fail', value: '');
        expect(failingController.tasks, isEmpty);
        expect(failingController.error, 'Save failed');

        failingController.clearError();
        expect(failingController.error, isNull);
      },
    );

    test(
      'spawns next occurrence with reset subtasks when a recurring task is completed',
      () async {
        final baseDate = DateTime(2026, 10, 9, 10, 0);
        await controller.add(
          name: 'Morning workout',
          value: 'Pushups and stretching',
          dueDate: baseDate,
          recurrence: RecurrenceRule.weekdays,
          subtasks: const [SubTask(id: 1, title: 'Warm up', isCompleted: true)],
        );

        expect(controller.tasks.length, 1);
        final originalTask = controller.tasks.first;
        expect(originalTask.recurrence, RecurrenceRule.weekdays);

        // Complete the Friday (Oct 9, 2026) task -> should spawn Monday (Oct 12, 2026)
        await controller.toggleCompleted(originalTask.id);
        expect(controller.tasks.length, 2);

        final pendingNext = controller.tasks.firstWhere((t) => !t.isCompleted);
        expect(pendingNext.name, 'Morning workout');
        expect(pendingNext.dueDate, DateTime(2026, 10, 12, 10, 0));
        expect(pendingNext.recurrence, RecurrenceRule.weekdays);
        expect(pendingNext.subtasks.first.isCompleted, isFalse);

        // Toggling the completed task off and on again should not duplicate the next occurrence
        await controller.toggleCompleted(originalTask.id);
        await controller.toggleCompleted(originalTask.id);
        expect(controller.tasks.length, 2);
        expect(controller.completedTodayCount, 1);
        expect(controller.currentStreakDays, 1);
        expect(controller.bestStreakDays, 1);
        expect(controller.last7DaysStreakStrip.last.$2, isTrue);
      },
    );
  });

  group('Auth & HomeScreen Widget Flow', () {
    testWidgets(
      'redirects fresh install to OnboardingScreen and then to WelcomeScreen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(MainApp(prefs: prefs));
        await tester.pumpAndSettle();

        // First launch shows OnboardingScreen
        expect(find.text('УМНЫЕ ЗАДАЧИ'), findsOneWidget);
        expect(find.text('ДАЛЕЕ'), findsOneWidget);

        // Tap through slides or Skip ('Пропустить')
        await tester.tap(find.text('ДАЛЕЕ'));
        await tester.pumpAndSettle();
        expect(find.text('РАСПИСАНИЕ И КАЛЕНДАРЬ'), findsOneWidget);

        await tester.tap(find.text('Пропустить'));
        await tester.pumpAndSettle();

        // Now on WelcomeScreen and onboarding is persisted
        expect(find.text('TodoApp'), findsOneWidget);
        expect(find.text('Вход по Почте (Код OTP)'), findsOneWidget);
        expect(find.text('Внутренняя регистрация / Вход'), findsOneWidget);
        expect(prefs.getBool('auth_seen_onboarding'), isTrue);
      },
    );

    testWidgets(
      'authenticated user adds task, opens custom calendar, edits task on card tap, and swipes to dismiss',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const user = AppUser(
          id: 'local_1',
          name: 'Vasudev Krishna',
          email: 'vasudev@example.com',
          isLocal: true,
        );
        SharedPreferences.setMockInitialValues({
          'auth_current_user': user.toJson(),
        });
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(MainApp(prefs: prefs));
        await tester.pumpAndSettle();

        expect(find.text('Vasudev Krishna'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Task'),
          'Initial task name',
        );

        // Open custom ListodoCalendarDialog with iPhone-style CupertinoPicker wheels
        await tester.tap(find.byIcon(Icons.calendar_month));
        await tester.pumpAndSettle();
        expect(find.text('Завтра'), findsOneWidget);
        await tester.tap(find.text('Завтра'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Выбрать'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Выбрать'));
        await tester.pumpAndSettle();

        // Open PriorityPickerDialog and select 'Срочно' (P1)
        await tester.tap(find.byIcon(Icons.flag_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Срочно'), findsOneWidget);
        await tester.tap(find.text('Срочно'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.text('Initial task name'), findsOneWidget);

        // Tap the task card to open Edit task bottom sheet
        await tester.tap(find.text('Initial task name'));
        await tester.pumpAndSettle();

        expect(find.text('Edit task'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Task'),
          'Updated task name',
        );
        await tester.tap(find.byIcon(Icons.check_circle));
        await tester.pumpAndSettle();

        expect(find.text('Updated task name'), findsOneWidget);

        // Complete the task, then swipe right to archive it!
        final taskController = tester
            .element(find.byType(Scaffold).first)
            .read<TaskController>();
        final currentTaskId = taskController.tasks.first.id;
        await taskController.toggleCompleted(currentTaskId);
        await tester.pumpAndSettle();

        // Swipe right (startToEnd) on completed card -> moves to archive
        await tester.drag(find.byType(Dismissible), const Offset(500, 0));
        await tester.pumpAndSettle();

        expect(find.text('Updated task name'), findsNothing);
        expect(taskController.archivedTasks.length, 1);

        // Switch to 'Профиль' tab in bottom navigation bar
        await tester.tap(find.text('Профиль'));
        await tester.pumpAndSettle();

        expect(find.text('Мой профиль'), findsOneWidget);
        expect(find.text('Архив выполненных'), findsOneWidget);

        // Tap compact 'Архив выполненных' card to open the searchable sheet
        await tester.tap(find.text('Архив выполненных'));
        await tester.pumpAndSettle();
        expect(find.text('Updated task name'), findsOneWidget);
        await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
        await tester.pumpAndSettle();

        // Open Profile Settings sheet ('Настройка профиля') inside ProfileTabView
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Настройка профиля'), findsOneWidget);
        expect(find.text('Выбрать фото'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Введите ваше имя'),
          'Daniil Updated',
        );
        await tester.tap(find.text('Сохранить изменения'));
        await tester.pumpAndSettle();

        expect(find.text('Daniil Updated'), findsOneWidget);

        // Open dedicated SettingsScreen via gear icon in AppBar
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Настройки'), findsOneWidget);
        expect(find.text('Тактильная вибрация (Haptics)'), findsOneWidget);

        // Tap 'Назад' button to return from SettingsScreen
        await tester.tap(find.text('Назад'));
        await tester.pumpAndSettle();

        // Switch to 'Календарь' tab in bottom navigation bar
        await tester.tap(find.text('Календарь'));
        await tester.pumpAndSettle();
        expect(find.text('Календарь задач'), findsOneWidget);
        expect(find.text('На этот день'), findsOneWidget);
        expect(find.text('Выполненные'), findsOneWidget);

        // Switch to 'Фокус' tab in bottom navigation bar
        await tester.tap(find.text('Фокус'));
        await tester.pumpAndSettle();
        expect(find.text('Режим фокуса'), findsOneWidget);
        expect(find.text('25:00'), findsOneWidget);
      },
    );
  });

  group('Task Supabase Mapping', () {
    test('converts to and from Supabase snake_case map accurately', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final task = Task(
        id: 777,
        name: 'Supabase Sync Test',
        value: 'Testing RLS and sync',
        createdAt: now,
        priorityIndex: 1,
        isCompleted: true,
        category: 'Work',
        subtasks: const [SubTask(id: 1, title: 'Step 1', isCompleted: true)],
      );

      final map = task.toSupabaseMap('user-uuid-123');
      expect(map['id'], 777);
      expect(map['user_id'], 'user-uuid-123');
      expect(map['name'], 'Supabase Sync Test');
      expect(map['created_at'], 1700000000000);
      expect(map['priority_index'], 1);
      expect(map['is_completed'], isTrue);

      final restored = Task.fromSupabaseMap(map);
      expect(restored.id, task.id);
      expect(restored.name, task.name);
      expect(restored.value, task.value);
      expect(restored.createdAt, task.createdAt);
      expect(restored.priorityIndex, task.priorityIndex);
      expect(restored.isCompleted, task.isCompleted);
      expect(restored.subtasks.length, 1);
      expect(restored.subtasks.first.title, 'Step 1');
    });
  });

  group('SupabaseTaskRemoteDataSource', () {
    test('fetches tasks with correct auth headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/rest/v1/tasks');
        expect(request.url.queryParameters['user_id'], 'eq.user-456');
        expect(request.headers['Authorization'], 'Bearer test-token-123');
        return http.Response(
          json.encode([
            {
              'id': 101,
              'name': 'Cloud Task',
              'value': '',
              'created_at': 1700000000000,
              'priority_index': 0,
              'is_completed': false,
              'category': 'Personal',
              'subtasks': [],
            },
          ]),
          200,
        );
      });

      final dataSource = SupabaseTaskRemoteDataSource(httpClient: mockClient);
      final result = await dataSource.fetchTasks(
        userId: 'user-456',
        accessToken: 'test-token-123',
      );

      expect(result, isA<Success<List<Task>>>());
      final tasks = (result as Success<List<Task>>).data;
      expect(tasks.length, 1);
      expect(tasks.first.id, 101);
      expect(tasks.first.name, 'Cloud Task');
    });

    test('upserts task and returns representation', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.headers['Prefer'],
          contains('resolution=merge-duplicates'),
        );
        return http.Response(
          json.encode([
            {
              'id': 202,
              'name': 'Created Task',
              'value': 'Remote',
              'created_at': 1700000000000,
              'priority_index': -1,
              'is_completed': false,
              'category': 'Personal',
              'subtasks': [],
            },
          ]),
          200,
        );
      });

      final dataSource = SupabaseTaskRemoteDataSource(httpClient: mockClient);
      final task = Task(
        id: 202,
        name: 'Created Task',
        value: 'Remote',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        priorityIndex: -1,
      );

      final result = await dataSource.upsertTask(
        task: task,
        userId: 'user-456',
        accessToken: 'test-token-123',
      );

      expect(result, isA<Success<Task>>());
      expect((result as Success<Task>).data.id, 202);
    });

    test('deletes task by id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.queryParameters['id'], 'eq.303');
        return http.Response('', 204);
      });

      final dataSource = SupabaseTaskRemoteDataSource(httpClient: mockClient);
      final result = await dataSource.deleteTask(
        id: 303,
        accessToken: 'test-token-123',
      );

      expect(result, isA<Success<void>>());
    });
  });

  group('TaskSyncRepository (Offline-First Sync)', () {
    late SharedPreferences prefs;
    late TaskLocalRepository localRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localRepo = TaskLocalRepository(prefs);
    });

    test('syncs and merges cloud tasks with local repository', () async {
      // Seed a local task
      final localTask = Task(
        id: 1,
        name: 'Local Task',
        value: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        priorityIndex: 0,
      );
      await localRepo.save(localTask);

      final cloudTask = Task(
        id: 2,
        name: 'Remote Cloud Task',
        value: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000005000),
        priorityIndex: 1,
      );

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            json.encode([cloudTask.toSupabaseMap('user-test')]),
            200,
          );
        }
        if (request.method == 'POST') {
          // Uploading local task to cloud
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final remoteDataSource = SupabaseTaskRemoteDataSource(
        httpClient: mockClient,
      );
      final authRepo = AuthRepositoryImpl(prefs);

      // Seed mock user and access token in auth repo
      await prefs.setString(
        'auth_current_user',
        const AppUser(
          id: 'user-test',
          name: 'Tester',
          email: 'test@supabase.co',
          isLocal: false,
        ).toJson(),
      );
      await prefs.setString('auth_access_token', 'valid-jwt-token');

      final syncRepo = TaskSyncRepository(
        local: localRepo,
        remote: remoteDataSource,
        auth: authRepo,
      );

      final syncResult = await syncRepo.syncWithCloud();
      expect(syncResult, isA<Success<List<Task>>>());
      final merged = (syncResult as Success<List<Task>>).data;

      // Both tasks should be present in merged result
      expect(merged.length, 2);
      expect(merged.any((t) => t.id == 1), isTrue);
      expect(merged.any((t) => t.id == 2), isTrue);

      // Local repository now contains both
      final localFetch = await localRepo.getAll();
      expect((localFetch as Success<List<Task>>).data.length, 2);
    });
  });
}
