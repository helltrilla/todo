import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/pomodoro_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

/// Test double implementing [INotificationService] for deterministic unit and widget testing.
/// Eliminates all native platform channel dependencies in tests.
class MockNotificationService implements INotificationService {
  final List<Task> syncedTasks = [];
  final List<int> canceledTaskIds = [];
  int cancelAllCount = 0;
  final List<String?> focusCompletedTaskNames = [];
  final List<String> mediaCommandsSent = [];
  bool requestedPermissions = false;

  @override
  Future<bool> initialize() => requestPermissions();

  @override
  Future<bool> requestPermissions() async {
    requestedPermissions = true;
    return true;
  }

  @override
  Future<void> syncTaskNotifications(Task task) async {
    syncedTasks.add(task);
  }

  @override
  Future<void> scheduleTaskNotification(Task task) => syncTaskNotifications(task);

  @override
  Future<void> cancelTaskNotifications(int taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> cancelNotification(int id) => cancelTaskNotifications(id);

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCount++;
  }

  @override
  Future<void> cancelAll() => cancelAllNotifications();

  @override
  Future<void> registerQuickActionHandler(
    ValueChanged<String> onQuickAction,
  ) async {}

  @override
  Future<void> sendFocusCompletedNotification({String? taskName}) async {
    focusCompletedTaskNames.add(taskName);
  }

  @override
  Future<bool> sendTestNotification() async => true;

  @override
  Future<String?> pickProfileImage() async => null;

  @override
  Future<void> setAmbientSound({
    required String sound,
    double volume = 0.45,
  }) async {}

  @override
  Future<bool> openExternalUrl({
    required String url,
    String? fallbackUrl,
  }) async => true;

  @override
  Future<void> sendMediaCommand(String command) async {
    mediaCommandsSent.add(command);
  }

  @override
  Future<bool> getMediaPlaybackState() async => false;

  @override
  Future<double> getSystemVolume() async => 0.65;

  @override
  Future<void> setSystemVolume(double volume) async {}
}

class FakeTaskRepository implements ITaskRepository {
  final List<Task> tasks = [];

  @override
  Future<Result<List<Task>>> getAll() async => Success(List.unmodifiable(tasks));

  @override
  Future<Result<Task>> save(Task task) async {
    tasks.add(task);
    return Success(task);
  }

  @override
  Future<Result<Task>> update(Task task) async {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) tasks[idx] = task;
    return Success(task);
  }

  @override
  Future<Result<void>> delete(int id) async {
    tasks.removeWhere((t) => t.id == id);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    tasks.removeWhere((t) => t.isCompleted);
    return const Success(null);
  }

  @override
  List<String> getCategories() => ['Work', 'Personal'];

  @override
  Future<Result<void>> saveCategories(List<String> categories) async =>
      const Success(null);

  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() => {};

  @override
  Future<Result<void>> saveCategoryStyles(Map<String, TaskCategoryStyle> styles) async =>
      const Success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig Security and Configuration Tests', () {
    test('isConfigured is false and validate() returns false when credentials are empty', () {
      // In test runner without --dart-define, default is empty
      expect(AppConfig.supabaseUrl, '');
      expect(AppConfig.supabaseAnonKey, '');
      expect(AppConfig.isConfigured, isFalse);
      expect(AppConfig.appVersion, isNotEmpty);
      expect(AppConfig.schemaVersion, equals(1));

      final isValid = AppConfig.validate();
      expect(isValid, isFalse);
    });
  });

  group('INotificationService Dependency Injection & Mocking Tests', () {
    late MockNotificationService mockNotifications;
    late FakeTaskRepository fakeRepository;
    late TaskController taskController;

    setUp(() {
      mockNotifications = MockNotificationService();
      fakeRepository = FakeTaskRepository();
      taskController = TaskController(
        fakeRepository,
        notificationService: mockNotifications,
      );
    });

    test('TaskController schedules notification via injected INotificationService upon add', () async {
      final dueDate = DateTime.now().add(const Duration(hours: 2));
      await taskController.add(
        name: 'Buy groceries',
        value: '',
        dueDate: dueDate,
        reminderOffsetMinutes: 15,
      );

      // Verify notification service was called without invoking native platform channels
      expect(mockNotifications.syncedTasks.length, 1);
      final syncedTask = mockNotifications.syncedTasks.first;
      expect(syncedTask.name, 'Buy groceries');
      expect(syncedTask.reminderOffsetMinutes, 15);
      expect(syncedTask.dueDate, dueDate);
      expect(taskController.notificationService, same(mockNotifications));
    });

    test('TaskController cancels notification via injected INotificationService upon delete', () async {
      final task = Task(
        id: 42,
        name: 'Urgent Task',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1,
      );
      await fakeRepository.save(task);
      await taskController.load();

      await taskController.delete(42);

      expect(mockNotifications.canceledTaskIds, contains(42));
    });

    test('PomodoroController dispatches focus completed notification via injected INotificationService', () async {
      SharedPreferences.setMockInitialValues({'focus_selected_minutes': 25});
      final prefs = await SharedPreferences.getInstance();

      final pomodoroController = PomodoroController(
        prefs: prefs,
        notificationService: mockNotifications,
      );

      await pomodoroController.selectPreset(25);
      pomodoroController.setFocusedTaskId(99, taskName: 'Write Documentation');

      expect(pomodoroController.notificationService, same(mockNotifications));

      // Emulate session finish (e.g. tick countdown or complete)
      await pomodoroController.completeSessionForTesting();

      // Verify the controller interacted with our mock notification service
      expect(mockNotifications.focusCompletedTaskNames, contains('Write Documentation'));
    });
  });
}
