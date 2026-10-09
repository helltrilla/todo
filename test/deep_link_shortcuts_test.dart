import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/data/services/smart_task_parser_impl.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/add_task_sheet.dart';

class DummyTaskRepo implements ITaskRepository {
  @override
  Future<Result<List<Task>>> getAll() async => const Success([]);
  @override
  Future<Result<void>> save(Task task) async => const Success(null);
  @override
  Future<Result<void>> update(Task task) async => const Success(null);
  @override
  Future<Result<void>> delete(int id) async => const Success(null);
  @override
  Future<Result<void>> deleteCompleted() async => const Success(null);
  @override
  List<String> getCategories() => ['Work', 'Personal', 'Покупки'];
  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() => {};
  @override
  Future<Result<void>> saveCategories(List<String> categories) async => const Success(null);
  @override
  Future<Result<void>> saveCategoryStyles(Map<String, TaskCategoryStyle> styles) async => const Success(null);
}

void main() {
  group('Deep Link URL Schemes & Siri/Assistant Shortcuts', () {
    test('parses tasks/new deep link parameters accurately', () {
      final uri = Uri.parse('todo://tasks/new?title=%D0%9A%D1%83%D0%BF%D0%B8%D1%82%D1%8C%20%D1%85%D0%BB%D0%B5%D0%B1&category=%D0%9F%D0%BE%D0%BA%D1%83%D0%BF%D0%BA%D0%B8&priority=0');
      expect(uri.scheme, equals('todo'));
      expect(uri.host, equals('tasks'));
      expect(uri.path, equals('/new'));
      expect(uri.queryParameters['title'], equals('Купить хлеб'));
      expect(uri.queryParameters['category'], equals('Покупки'));
      expect(uri.queryParameters['priority'], equals('0'));
    });

    test('parses voice quick intent deep link accurately', () {
      final uri = Uri.parse('todo://voice/quick');
      expect(uri.scheme, equals('todo'));
      expect(uri.host, equals('voice'));
      expect(uri.path, equals('/quick'));
    });

    test('parses matrix view deep link accurately', () {
      final uri = Uri.parse('todo://matrix');
      expect(uri.scheme, equals('todo'));
      expect(uri.host, equals('matrix'));
    });
  });

  group('AddTaskSheet Prefilled via Native Shortcut', () {
    testWidgets('populates title and category fields from native shortcut parameters', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TaskController(DummyTaskRepo());
      await controller.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskController>.value(value: controller),
            Provider<ISmartTaskParser>.value(
              value: SmartTaskParserImpl(prefs: prefs),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddTaskSheet(
                initialTitle: 'Купить свежие фрукты',
                initialCategory: 'Покупки',
                initialPriorityIndex: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Купить свежие фрукты'), findsOneWidget);
      expect(find.text('Покупки'), findsOneWidget);
    });
  });
}
