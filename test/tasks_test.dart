import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/main.dart';

class _FailingRepository implements ITaskRepository {
  @override
  Future<List<Task>> getAll() async => throw Exception('Read failed');

  @override
  Future<void> save(Task task) async => throw Exception('Save failed');

  @override
  Future<void> delete(int id) async => throw Exception('Delete failed');
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
    });

    test('Task copyWith updates specified fields', () {
      final task = Task(
        id: 1,
        name: 'Old',
        value: 'Desc',
        createdAt: DateTime(2026),
        priorityIndex: -1,
      );
      final updated = task.copyWith(name: 'New', priorityIndex: 2);
      expect(updated.id, 1);
      expect(updated.name, 'New');
      expect(updated.value, 'Desc');
      expect(updated.priority, PriorityLevel.p3);
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

    test('saves, loads, and deletes tasks', () async {
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

      final all = await repo.getAll();
      expect(all.length, 2);
      expect(all.map((e) => e.id), [10, 20]);

      await repo.delete(10);
      final remaining = await repo.getAll();
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

    test('adds and sorts tasks by priority then newest createdAt', () async {
      await controller.add(name: 'Low priority', value: '', priorityIndex: 5);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.add(name: 'High priority', value: '', priorityIndex: 0);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.add(name: 'No priority', value: '', priorityIndex: -1);

      expect(controller.tasks.length, 3);
      expect(controller.tasks[0].name, 'High priority');
      expect(controller.tasks[1].name, 'Low priority');
      expect(controller.tasks[2].name, 'No priority');
    });

    test(
      'rolls back optimistic add and delete on repository failure',
      () async {
        final failingController = TaskController(_FailingRepository());

        await failingController.add(name: 'Will fail', value: '');
        expect(failingController.tasks, isEmpty);
        expect(failingController.error, isNotNull);

        failingController.clearError();
        expect(failingController.error, isNull);
      },
    );
  });

  group('HomeScreen Widget Test', () {
    testWidgets('renders empty state and adds a task via bottom sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(MainApp(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Tasks'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add task'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Write tests');
      await tester.enterText(find.byType(TextField).last, 'Ensure 100% pass');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('Ensure 100% pass'), findsOneWidget);
    });
  });
}
