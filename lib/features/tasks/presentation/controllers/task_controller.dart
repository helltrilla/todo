import 'package:flutter/foundation.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Application-layer controller for task management.
///
/// State ownership: task list, loading flag, error message.
/// Uses optimistic updates — UI responds instantly, rolls back on failure.
class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final ITaskRepository _repository;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  /// Tasks sorted by priority (highest first), then by creation date (newest first).
  List<Task> get tasks => List.unmodifiable(_sorted(_tasks));
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _repository.getAll();
    } catch (e) {
      _error = 'Не удалось загрузить задачи';
      debugPrint('TaskController.load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add({
    required String name,
    required String value,
    DateTime? dueDate,
    int priorityIndex = -1,
  }) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      value: value,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priorityIndex: priorityIndex,
    );

    // Optimistic update — add to list before persistence.
    _tasks = [..._tasks, task];
    notifyListeners();

    try {
      await _repository.save(task);
    } catch (e) {
      // Rollback on failure.
      _tasks = _tasks.where((t) => t.id != task.id).toList();
      _error = 'Не удалось сохранить задачу';
      debugPrint('TaskController.add error: $e');
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    final snapshot = List<Task>.from(_tasks);

    // Optimistic update — remove from list before persistence.
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();

    try {
      await _repository.delete(id);
    } catch (e) {
      // Rollback on failure.
      _tasks = snapshot;
      _error = 'Не удалось удалить задачу';
      debugPrint('TaskController.delete error: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Sort: highest priority first (index 0 = p1 = most urgent),
  /// then by creation date descending (newest on top).
  List<Task> _sorted(List<Task> tasks) {
    return [...tasks]..sort((a, b) {
      // Tasks without priority (index == -1) go to the bottom.
      final aPriority = a.priorityIndex == -1 ? 999 : a.priorityIndex;
      final bPriority = b.priorityIndex == -1 ? 999 : b.priorityIndex;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
