import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/tasks/data/repositories/task_sync_repository.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Application-layer controller for task management.
///
/// Consumes [Result<T>] from [ITaskRepository] without generic try/catch
/// in the presentation layer, strictly adhering to AGENTS.md & ARCHITECTURE.md.
class TaskController extends ChangeNotifier {
  TaskController(this._repository) {
    _categories = _repository.getCategories();
    _categoryStyles = _repository.getCategoryStyles();
  }

  final ITaskRepository _repository;

  static const String allCategory = 'All Task';
  static const String globalCategory = 'Общее';

  List<Task> _tasks = [];
  List<String> _categories = ['Work', 'Personal'];
  Map<String, TaskCategoryStyle> _categoryStyles = {};
  String _selectedCategory = allCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isSyncing = false;
  String? _syncError;

  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncedAt {
    final repo = _repository;
    return repo is TaskSyncRepository ? repo.lastSyncedAt : null;
  }

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

  /// Returns the custom or default [TaskCategoryStyle] for [categoryName].
  TaskCategoryStyle styleForCategory(String categoryName) {
    final key = categoryName.trim().toLowerCase();
    return _categoryStyles[key] ?? TaskCategoryStyle.defaultFor(categoryName);
  }

  /// Total count of all tasks (unfiltered).
  int get totalTasksCount => _tasks.length;

  /// Count of completed tasks (unfiltered).
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  /// Count of pending (incomplete) tasks (unfiltered).
  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;

  /// Count of unfinished urgent (p1) tasks (unfiltered).
  int get urgentPendingCount => _tasks
      .where((t) => !t.isCompleted && t.priority == PriorityLevel.p1)
      .length;

  /// All tasks moved to archive via right-swipe on completed cards.
  List<Task> get archivedTasks {
    final list = _tasks.where((t) => t.isArchived).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  /// Count of archived tasks.
  int get archivedTasksCount => _tasks.where((t) => t.isArchived).length;

  /// Total minutes spent in Focus mode across all tasks.
  int get totalFocusMinutes =>
      _tasks.fold<int>(0, (sum, t) => sum + t.focusMinutes);

  /// Total completed Pomodoro focus sessions across all tasks.
  int get totalPomodoroSessions =>
      _tasks.fold<int>(0, (sum, t) => sum + t.pomodoroCount);

  /// Count of tasks completed today.
  int get completedTodayCount {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (!t.isCompleted) return false;
      final stamp = t.completedAt ?? t.dueDate ?? t.createdAt;
      return stamp.year == now.year &&
          stamp.month == now.month &&
          stamp.day == now.day;
    }).length;
  }

  /// Set of normalized calendar dates (midnight) on which at least one task was completed.
  Set<DateTime> get _completedCalendarDays {
    final days = <DateTime>{};
    for (final t in _tasks) {
      if (!t.isCompleted) continue;
      final stamp = t.completedAt ?? t.dueDate ?? t.createdAt;
      days.add(DateTime(stamp.year, stamp.month, stamp.day));
    }
    return days;
  }

  /// Current consecutive daily streak of completing at least 1 task per day.
  /// Remains active today if either today or yesterday has a completed task.
  int get currentStreakDays {
    final activeDays = _completedCalendarDays;
    if (activeDays.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    DateTime cursor;
    if (activeDays.contains(today)) {
      cursor = today;
    } else if (activeDays.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  /// Longest consecutive daily streak achieved across all completed tasks.
  int get bestStreakDays {
    final sorted = _completedCalendarDays.toList()..sort();
    if (sorted.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final expectedNext = DateTime(prev.year, prev.month, prev.day + 1);
      if (sorted[i] == expectedNext) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  /// Last 7 calendar days (ending today) paired with whether at least 1 task was completed.
  List<(DateTime, bool)> get last7DaysStreakStrip {
    final activeDays = _completedCalendarDays;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<(DateTime, bool)>.generate(7, (index) {
      final offset = 6 - index;
      final day = DateTime(today.year, today.month, today.day - offset);
      return (day, activeDays.contains(day));
    });
  }

  /// Returns non-archived tasks scheduled for [date] (or created on [date] if dueDate is null),
  /// filtered by completion status [completed] and sorted by priority.
  List<Task> tasksForDate(DateTime date, {required bool completed}) {
    final list = _tasks.where((t) {
      if (t.isArchived) return false;
      if (t.isCompleted != completed) return false;
      final target = t.dueDate ?? t.createdAt;
      return target.year == date.year &&
          target.month == date.month &&
          target.day == date.day;
    }).toList();

    list.sort((a, b) {
      final aPriority = a.priorityIndex == -1 ? 999 : a.priorityIndex;
      final bPriority = b.priorityIndex == -1 ? 999 : b.priorityIndex;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      final aTime = a.dueDate ?? a.createdAt;
      final bTime = b.dueDate ?? b.createdAt;
      return aTime.compareTo(bTime);
    });
    return list;
  }

  /// Returns true if there is at least one non-archived task on [date].
  bool hasTasksOnDate(DateTime date) {
    return _tasks.any((t) {
      if (t.isArchived) return false;
      final target = t.dueDate ?? t.createdAt;
      return target.year == date.year &&
          target.month == date.month &&
          target.day == date.day;
    });
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _categories = _repository.getCategories();
    _categoryStyles = _repository.getCategoryStyles();
    final result = await _repository.getAll();

    switch (result) {
      case Success(:final data):
        _tasks = data;
      case Error(:final failure):
        _error = failure.message;
    }

    _isLoading = false;
    notifyListeners();

    if (_repository is TaskSyncRepository) {
      unawaited(syncWithCloud());
    }
  }

  /// Triggers two-way cloud synchronization with Supabase.
  Future<bool> syncWithCloud() async {
    final repo = _repository;
    if (repo is! TaskSyncRepository) return false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    final result = await repo.syncWithCloud();
    _isSyncing = false;

    switch (result) {
      case Success(:final data):
        _tasks = data;
        notifyListeners();
        return true;
      case Error(:final failure):
        _syncError = failure.message;
        notifyListeners();
        return false;
    }
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

  Future<void> addCategory(
    String categoryName, {
    int? iconIndex,
    int? colorIndex,
  }) async {
    final clean = categoryName.trim();
    if (clean.isEmpty ||
        clean.toLowerCase() == allCategory.toLowerCase() ||
        clean.toLowerCase() == globalCategory.toLowerCase() ||
        _categories.any((c) => c.toLowerCase() == clean.toLowerCase())) {
      return;
    }
    _categories = [..._categories, clean];
    _selectedCategory = clean;

    final fallback = TaskCategoryStyle.defaultFor(clean);
    final style = TaskCategoryStyle(
      name: clean,
      iconIndex: iconIndex ?? fallback.iconIndex,
      colorIndex: colorIndex ?? fallback.colorIndex,
    );
    _categoryStyles = <String, TaskCategoryStyle>{
      ..._categoryStyles,
      clean.toLowerCase(): style,
    };
    notifyListeners();

    final result = await _repository.saveCategories(_categories);
    await _repository.saveCategoryStyles(_categoryStyles);
    if (result case Error(:final failure)) {
      _error = failure.message;
      notifyListeners();
    }
  }

  Future<void> removeCategory(String categoryName) async {
    final snapshot = List<String>.from(_categories);
    _categories = _categories
        .where((c) => c.toLowerCase() != categoryName.toLowerCase())
        .toList();
    if (_selectedCategory.toLowerCase() == categoryName.toLowerCase()) {
      _selectedCategory = allCategory;
    }
    notifyListeners();

    final result = await _repository.saveCategories(_categories);
    if (result case Error(:final failure)) {
      _categories = snapshot;
      _error = failure.message;
      notifyListeners();
    }
  }

  Future<void> add({
    required String name,
    required String value,
    DateTime? dueDate,
    int? reminderOffsetMinutes,
    int priorityIndex = -1,
    String? category,
    List<SubTask> subtasks = const [],
    RecurrenceRule recurrence = RecurrenceRule.none,
    bool isPinned = false,
  }) async {
    final effectiveCategory =
        category ??
        (_selectedCategory != allCategory ? _selectedCategory : globalCategory);

    final effectiveDueDate =
        dueDate ?? (recurrence.isRepeating ? DateTime.now() : null);

    final task = Task(
      id: _generateUniqueId(),
      name: name,
      value: value,
      createdAt: DateTime.now(),
      dueDate: effectiveDueDate,
      reminderOffsetMinutes: effectiveDueDate != null
          ? reminderOffsetMinutes
          : null,
      priorityIndex: priorityIndex,
      isPinned: isPinned,
      category: effectiveCategory,
      subtasks: subtasks,
      recurrence: recurrence,
    );

    _tasks = [..._tasks, task];
    notifyListeners();

    final result = await _repository.save(task);
    if (result case Error(:final failure)) {
      _tasks = _tasks.where((t) => t.id != task.id).toList();
      _error = failure.message;
      notifyListeners();
      return;
    }

    unawaited(NotificationService.instance.syncTaskNotifications(task));
  }

  int _generateUniqueId() {
    var candidate = DateTime.now().millisecondsSinceEpoch;
    while (_tasks.any((t) => t.id == candidate)) {
      candidate++;
    }
    return candidate;
  }

  /// Updates all fields of an existing [updatedTask] with optimistic UI and rollback.
  /// If a recurring task transitions from incomplete to completed for the first time,
  /// automatically schedules its next occurrence.
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index == -1) return;

    final original = _tasks[index];
    final becomingCompleted = !original.isCompleted && updatedTask.isCompleted;
    final becomingIncomplete = original.isCompleted && !updatedTask.isCompleted;
    final shouldSpawnNext =
        becomingCompleted &&
        updatedTask.isRecurring &&
        !updatedTask.hasSpawnedNext;

    final effectiveUpdated = updatedTask.copyWith(
      hasSpawnedNext: shouldSpawnNext ? true : updatedTask.hasSpawnedNext,
      completedAt: becomingCompleted
          ? (updatedTask.completedAt ?? DateTime.now())
          : updatedTask.completedAt,
      clearCompletedAt: becomingIncomplete,
    );

    final nextList = List<Task>.from(_tasks);
    nextList[index] = effectiveUpdated;
    _tasks = nextList;
    notifyListeners();

    final result = await _repository.update(effectiveUpdated);
    if (result case Error(:final failure)) {
      final rollbackList = List<Task>.from(_tasks);
      final currentIndex = rollbackList.indexWhere(
        (t) => t.id == effectiveUpdated.id,
      );
      if (currentIndex != -1) {
        rollbackList[currentIndex] = original;
        _tasks = rollbackList;
      }
      _error = failure.message;
      notifyListeners();
      return;
    }

    unawaited(
      NotificationService.instance.syncTaskNotifications(effectiveUpdated),
    );

    if (shouldSpawnNext) {
      final baseDue = effectiveUpdated.dueDate ?? DateTime.now();
      final nextDue = effectiveUpdated.recurrence.nextDueDate(baseDue);
      final nextTask = Task(
        id: _generateUniqueId(),
        name: effectiveUpdated.name,
        value: effectiveUpdated.value,
        createdAt: DateTime.now(),
        dueDate: nextDue,
        reminderOffsetMinutes: effectiveUpdated.reminderOffsetMinutes ?? 15,
        priorityIndex: effectiveUpdated.priorityIndex,
        category: effectiveUpdated.category,
        recurrence: effectiveUpdated.recurrence,
        subtasks: effectiveUpdated.subtasks
            .map((s) => s.copyWith(isCompleted: false))
            .toList(),
      );
      _tasks = [..._tasks, nextTask];
      notifyListeners();

      final saveResult = await _repository.save(nextTask);
      if (saveResult case Error(:final failure)) {
        _tasks = _tasks.where((t) => t.id != nextTask.id).toList();
        _error = failure.message;
        notifyListeners();
      } else {
        unawaited(NotificationService.instance.syncTaskNotifications(nextTask));
      }
    }
  }

  Future<void> toggleCompleted(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(current.copyWith(isCompleted: !current.isCompleted));
  }

  /// Toggles the pinned status of a task so it stays at the top of the list.
  Future<void> togglePin(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(current.copyWith(isPinned: !current.isPinned));
  }

  /// Records a completed Pomodoro focus session (+1 session and +[minutes] focus time) on [taskId].
  Future<void> recordFocusSession(int taskId, {required int minutes}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(
      current.copyWith(
        pomodoroCount: current.pomodoroCount + 1,
        focusMinutes: current.focusMinutes + (minutes > 0 ? minutes : 1),
      ),
    );
  }

  /// Toggles a single [SubTask] inside a [Task].
  /// If all subtasks become completed, automatically marks the parent task completed.
  Future<void> toggleSubTask(int taskId, int subTaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final current = _tasks[index];
    final updatedSubtasks = current.subtasks.map((s) {
      if (s.id == subTaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final allDone =
        updatedSubtasks.isNotEmpty &&
        updatedSubtasks.every((s) => s.isCompleted);

    await updateTask(
      current.copyWith(
        subtasks: updatedSubtasks,
        isCompleted: allDone ? true : current.isCompleted,
      ),
    );
  }

  /// Moves a completed task into the archive so it leaves the main board
  /// but stays viewable in the archive section.
  Future<void> archiveTask(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(current.copyWith(isCompleted: true, isArchived: true));
  }

  /// Restores an archived task back to the main board.
  Future<void> unarchiveTask(int id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    await updateTask(current.copyWith(isArchived: false));
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
      return;
    }

    unawaited(NotificationService.instance.cancelTaskNotifications(id));
  }

  Future<void> clearCompleted() async {
    final snapshot = List<Task>.from(_tasks);
    _tasks = _tasks.where((t) => !t.isCompleted).toList();
    notifyListeners();

    final result = await _repository.deleteCompleted();
    if (result case Error(:final failure)) {
      _tasks = snapshot;
      _error = failure.message;
      notifyListeners();
    }
  }

  /// Deletes all tasks when wiping account data.
  Future<void> clearAllTasks() async {
    final ids = _tasks.map((t) => t.id).toList();
    _tasks = [];
    notifyListeners();
    for (final id in ids) {
      await _repository.delete(id);
    }
    unawaited(NotificationService.instance.cancelAllNotifications());
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
      if (t.isArchived) return false;

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
      if (!a.isCompleted && a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aPriority = a.priorityIndex == -1 ? 999 : a.priorityIndex;
      final bPriority = b.priorityIndex == -1 ? 999 : b.priorityIndex;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
