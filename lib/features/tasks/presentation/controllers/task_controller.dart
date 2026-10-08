import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Application-layer controller for task management.
///
/// Consumes [Result<T>] from [ITaskRepository] without generic try/catch
/// in the presentation layer, strictly adhering to AGENTS.md & ARCHITECTURE.md.
class TaskController extends ChangeNotifier {
  TaskController(this._repository) {
    _categories = _repository.getCategories();
  }

  final ITaskRepository _repository;

  static const String allCategory = 'All Task';
  static const String globalCategory = 'Общее';

  List<Task> _tasks = [];
  List<String> _categories = ['Work', 'Personal'];
  String _selectedCategory = allCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  /// All filtered and sorted tasks.
  List<Task> get tasks => List.unmodifiable(_filteredAndSorted(_tasks));

  /// Tasks scheduled for future dates (strictly after today).
  List<Task> get futureTasks {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return tasks
        .where((t) => t.dueDate != null && t.dueDate!.isAfter(todayEnd))
        .toList();
  }

  /// Tasks scheduled for today, earlier, or without a specific future date.
  List<Task> get todayTasks {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return tasks
        .where((t) => t.dueDate == null || !t.dueDate!.isAfter(todayEnd))
        .toList();
  }

  List<String> get categories => List.unmodifiable(_categories);
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _categories = _repository.getCategories();
    final result = await _repository.getAll();

    switch (result) {
      case Success(:final data):
        _tasks = data;
      case Error(:final failure):
        _error = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addCategory(String categoryName) async {
    final clean = categoryName.trim();
    if (clean.isEmpty ||
        clean.toLowerCase() == allCategory.toLowerCase() ||
        clean.toLowerCase() == globalCategory.toLowerCase() ||
        _categories.any((c) => c.toLowerCase() == clean.toLowerCase())) {
      return;
    }
    _categories = [..._categories, clean];
    _selectedCategory = clean;
    notifyListeners();

    final result = await _repository.saveCategories(_categories);
    if (result case Error(:final failure)) {
      _error = failure.message;
      notifyListeners();
    }
  }

  Future<void> add({
    required String name,
    required String value,
    DateTime? dueDate,
    int priorityIndex = -1,
    String? category,
  }) async {
    final effectiveCategory =
        category ??
        (_selectedCategory != allCategory ? _selectedCategory : globalCategory);

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      value: value,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priorityIndex: priorityIndex,
      category: effectiveCategory,
    );

    _tasks = [..._tasks, task];
    notifyListeners();

    final result = await _repository.save(task);
    if (result case Error(:final failure)) {
      _tasks = _tasks.where((t) => t.id != task.id).toList();
      _error = failure.message;
      notifyListeners();
    }
  }

  /// Updates all fields of an existing [updatedTask] with optimistic UI and rollback.
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index == -1) return;

    final original = _tasks[index];
    final nextList = List<Task>.from(_tasks);
    nextList[index] = updatedTask;
    _tasks = nextList;
    notifyListeners();

    final result = await _repository.update(updatedTask);
    if (result case Error(:final failure)) {
      final rollbackList = List<Task>.from(_tasks);
      final currentIndex = rollbackList.indexWhere(
        (t) => t.id == updatedTask.id,
      );
      if (currentIndex != -1) {
        rollbackList[currentIndex] = original;
        _tasks = rollbackList;
      }
      _error = failure.message;
      notifyListeners();
    }
  }

  Future<void> toggleCompleted(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(current.copyWith(isCompleted: !current.isCompleted));
  }

  Future<void> delete(int id) async {
    final snapshot = List<Task>.from(_tasks);

    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();

    final result = await _repository.delete(id);
    if (result case Error(:final failure)) {
      _tasks = snapshot;
      _error = failure.message;
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

  List<Task> _filteredAndSorted(List<Task> source) {
    final q = _searchQuery.toLowerCase();
    final filtered = source.where((t) {
      final isGlobalTask =
          t.category.toLowerCase() == globalCategory.toLowerCase() ||
          t.category.toLowerCase() == allCategory.toLowerCase();
      final isCriticalUnfinished =
          !t.isCompleted && t.priority == PriorityLevel.p1;

      final matchesCategory =
          _selectedCategory == allCategory ||
          isGlobalTask ||
          isCriticalUnfinished ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();
      if (!matchesCategory) return false;

      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.value.toLowerCase().contains(q);
    }).toList();

    return filtered..sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final aPriority = a.priorityIndex == -1 ? 999 : a.priorityIndex;
      final bPriority = b.priorityIndex == -1 ? 999 : b.priorityIndex;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
