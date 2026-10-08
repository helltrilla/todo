import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Persists tasks and custom categories in SharedPreferences.
/// Wraps all storage operations in [Result<T>] with [CacheFailure] on error.
class TaskLocalRepository implements ITaskRepository {
  TaskLocalRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'tasks';
  static const _categoriesKey = 'task_categories';
  static const defaultCategories = ['Work', 'Personal'];

  @override
  Future<Result<List<Task>>> getAll() async {
    try {
      final strings = _prefs.getStringList(_key) ?? [];
      return Success(strings.map(Task.fromJson).toList());
    } catch (_) {
      return const Error(CacheFailure('Не удалось загрузить задачи'));
    }
  }

  @override
  Future<Result<void>> save(Task task) async {
    try {
      final strings = List<String>.from(_prefs.getStringList(_key) ?? []);
      strings.add(task.toJson());
      final ok = await _prefs.setStringList(_key, strings);
      if (!ok) {
        return const Error(CacheFailure('Не удалось сохранить задачу'));
      }
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Не удалось сохранить задачу'));
    }
  }

  @override
  Future<Result<void>> update(Task task) async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(Task.fromJson);
      final updated = current
          .map((t) => t.id == task.id ? task.toJson() : t.toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        return const Error(CacheFailure('Не удалось обновить задачу'));
      }
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Не удалось обновить задачу'));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(Task.fromJson);
      final updated = current
          .where((t) => t.id != id)
          .map((t) => t.toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        return const Error(CacheFailure('Не удалось удалить задачу'));
      }
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Не удалось удалить задачу'));
    }
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(Task.fromJson);
      final updated = current
          .where((t) => !t.isCompleted)
          .map((t) => t.toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        return const Error(
          CacheFailure('Не удалось очистить выполненные задачи'),
        );
      }
      return const Success(null);
    } catch (_) {
      return const Error(
        CacheFailure('Не удалось очистить выполненные задачи'),
      );
    }
  }

  @override
  List<String> getCategories() {
    final saved = _prefs.getStringList(_categoriesKey);
    if (saved == null || saved.isEmpty) {
      return List<String>.from(defaultCategories);
    }
    return saved;
  }

  @override
  Future<Result<void>> saveCategories(List<String> categories) async {
    try {
      await _prefs.setStringList(_categoriesKey, categories);
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Не удалось сохранить категории'));
    }
  }
}
