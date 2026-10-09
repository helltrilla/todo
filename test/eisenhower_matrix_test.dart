import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/eisenhower_matrix_view.dart';

class InMemoryTaskRepository implements ITaskRepository {
  final List<Task> _storage = [];

  @override
  Future<Result<List<Task>>> getAll() async => Success(List.unmodifiable(_storage));

  @override
  Future<Result<void>> save(Task task) async {
    _storage.add(task);
    return const Success(null);
  }

  @override
  Future<Result<void>> update(Task task) async {
    final idx = _storage.indexWhere((e) => e.id == task.id);
    if (idx != -1) _storage[idx] = task;
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(int id) async {
    _storage.removeWhere((e) => e.id == id);
    return Success(null);
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    _storage.removeWhere((e) => e.isCompleted);
    return Success(null);
  }

  @override
  List<String> getCategories() => ['Work', 'Personal'];

  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() => {};

  @override
  Future<Result<void>> saveCategories(List<String> categories) async => Success(null);

  @override
  Future<Result<void>> saveCategoryStyles(Map<String, TaskCategoryStyle> styles) async => Success(null);
}

void main() {
  group('EisenhowerQuadrant Domain Logic', () {
    test('resolves correct quadrant based on explicit flags', () {
      final q1Task = Task(
        id: 1,
        name: 'Q1 Task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 3,
        isUrgent: true,
        isImportant: true,
      );
      expect(q1Task.quadrant, equals(EisenhowerQuadrant.q1));

      final q2Task = Task(
        id: 2,
        name: 'Q2 Task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
        isUrgent: false,
        isImportant: true,
      );
      expect(q2Task.quadrant, equals(EisenhowerQuadrant.q2));

      final q3Task = Task(
        id: 3,
        name: 'Q3 Task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
        isUrgent: true,
        isImportant: false,
      );
      expect(q3Task.quadrant, equals(EisenhowerQuadrant.q3));

      final q4Task = Task(
        id: 4,
        name: 'Q4 Task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
        isUrgent: false,
        isImportant: false,
      );
      expect(q4Task.quadrant, equals(EisenhowerQuadrant.q4));
    });

    test('falls back to priority index heuristics when flags are omitted', () {
      final p1Task = Task(
        id: 1,
        name: 'Fire task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0, // P1: Urgent & Important
      );
      expect(p1Task.quadrant, equals(EisenhowerQuadrant.q1));

      final p2Task = Task(
        id: 2,
        name: 'Strategic task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1, // P2: Important, not urgent by default
      );
      expect(p2Task.quadrant, equals(EisenhowerQuadrant.q2));

      final p4Task = Task(
        id: 3,
        name: 'Later task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 3, // P4: Neither urgent nor important
      );
      expect(p4Task.quadrant, equals(EisenhowerQuadrant.q4));
    });
  });

  group('TaskController Eisenhower Operations', () {
    late InMemoryTaskRepository repository;
    late TaskController controller;

    setUp(() async {
      repository = InMemoryTaskRepository();
      controller = TaskController(repository);
      await controller.load();
    });

    test('toggleViewMode switches between ListView and Eisenhower Matrix', () {
      expect(controller.isMatrixView, isFalse);
      controller.toggleViewMode();
      expect(controller.isMatrixView, isTrue);
      controller.toggleViewMode(false);
      expect(controller.isMatrixView, isFalse);
    });

    test('moveTaskToQuadrant updates urgency, importance, and priority correctly', () async {
      await controller.add(
        name: 'Черновик',
        value: '',
        priorityIndex: 3, // Initially P4
      );

      final task = controller.tasks.first;
      expect(task.quadrant, equals(EisenhowerQuadrant.q4));

      // Move to Q1 (Urgent & Important)
      await controller.moveTaskToQuadrant(task, EisenhowerQuadrant.q1);
      final updatedQ1 = controller.tasks.first;
      expect(updatedQ1.isUrgent, isTrue);
      expect(updatedQ1.isImportant, isTrue);
      expect(updatedQ1.priorityIndex, equals(0));
      expect(updatedQ1.quadrant, equals(EisenhowerQuadrant.q1));

      // Move to Q2 (Schedule)
      await controller.moveTaskToQuadrant(updatedQ1, EisenhowerQuadrant.q2);
      final updatedQ2 = controller.tasks.first;
      expect(updatedQ2.isUrgent, isFalse);
      expect(updatedQ2.isImportant, isTrue);
      expect(updatedQ2.priorityIndex, equals(1));
      expect(updatedQ2.quadrant, equals(EisenhowerQuadrant.q2));

      // Move to Q3 (Delegate)
      await controller.moveTaskToQuadrant(updatedQ2, EisenhowerQuadrant.q3);
      final updatedQ3 = controller.tasks.first;
      expect(updatedQ3.isUrgent, isTrue);
      expect(updatedQ3.isImportant, isFalse);
      expect(updatedQ3.priorityIndex, equals(2));
      expect(updatedQ3.quadrant, equals(EisenhowerQuadrant.q3));
    });

    test('tasksForQuadrant filters tasks precisely by quadrant', () async {
      await controller.add(name: 'Do Now', value: '', priorityIndex: 0);
      await controller.add(name: 'Plan Ahead', value: '', priorityIndex: 1);

      final q1List = controller.tasksForQuadrant(EisenhowerQuadrant.q1);
      expect(q1List.map((t) => t.name), contains('Do Now'));

      final q2List = controller.tasksForQuadrant(EisenhowerQuadrant.q2);
      expect(q2List.map((t) => t.name), contains('Plan Ahead'));
    });
  });

  group('EisenhowerMatrixView Widget Test', () {
    testWidgets('renders all four quadrants and task cards', (tester) async {
      final repository = InMemoryTaskRepository();
      final controller = TaskController(repository);
      await controller.load();
      await controller.add(name: 'Critical Hotfix', value: '', priorityIndex: 0);
      await controller.add(name: 'Architecture Roadmap', value: '', priorityIndex: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<TaskController>.value(
              value: controller,
              child: EisenhowerMatrixView(
                onEditTask: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Срочно и Важно'), findsOneWidget);
      expect(find.text('Не срочно, но Важно'), findsOneWidget);
      expect(find.text('Срочно, но Не важно'), findsOneWidget);
      expect(find.text('Не срочно и Не важно'), findsOneWidget);

      expect(find.text('Critical Hotfix'), findsOneWidget);
      expect(find.text('Architecture Roadmap'), findsOneWidget);
    });
  });
}
