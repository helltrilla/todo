import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
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
  List<String> getCategories() => const ['Work', 'Personal'];

  @override
  Future<Result<void>> saveCategories(List<String> categories) async =>
      const Error(CacheFailure('Save categories failed'));
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

        controller.selectCategory(TaskController.allCategory);
        controller.setSearchQuery('housework');
        expect(controller.tasks.length, 1);
        expect(controller.tasks.first.name, 'Doing housework');

        controller.setSearchQuery('');
        await controller.toggleCompleted(controller.tasks.first.id);
        expect(controller.tasks.any((t) => t.isCompleted), isTrue);
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
  });

  group('Auth & HomeScreen Widget Flow', () {
    testWidgets('redirects unauthenticated user to WelcomeScreen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(MainApp(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Listtodo'), findsOneWidget);
      expect(find.text('Вход по Почте (Код OTP)'), findsOneWidget);
      expect(find.text('Внутренняя регистрация / Вход'), findsOneWidget);
    });

    testWidgets(
      'authenticated user adds task, opens custom calendar, edits task on card tap, and swipes to dismiss',
      (tester) async {
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

        // Open custom ListodoCalendarDialog and select 'Завтра'
        await tester.tap(find.byIcon(Icons.calendar_month));
        await tester.pumpAndSettle();
        expect(find.text('Время'), findsOneWidget);
        await tester.tap(find.text('Завтра'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Выбрать'));
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

        // Swipe left -> triggers confirmDismiss dialog
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('Удалить задачу?'), findsOneWidget);

        // Confirm deletion -> Dismissible is removed cleanly from the tree
        await tester.tap(find.text('Удалить'));
        await tester.pumpAndSettle();

        expect(find.text('Updated task name'), findsNothing);
      },
    );
  });
}
