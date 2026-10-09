import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/tasks/data/models/task_model.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/models/task_category_style.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Persists tasks and custom categories in SharedPreferences using [TaskModel].
/// Wraps all storage operations in [Result<T>] with [CacheFailure] on error
/// and logs all failures via [AppLogger].
class TaskLocalRepository implements ITaskRepository {
  TaskLocalRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'tasks';
  static const _categoriesKey = 'task_categories';
  static const _categoryStylesKey = 'task_category_styles';
  static const defaultCategories = ['Work', 'Personal'];

  @override
  Future<Result<List<Task>>> getAll() async {
    try {
      final strings = _prefs.getStringList(_key) ?? [];
      final tasks = strings.map(TaskModel.fromJson).toList();
      return Success(tasks);
    } catch (e, st) {
      AppLogger.error('Failed to load tasks from local storage', e, st);
      return const Error(CacheFailure('Не удалось загрузить задачи'));
    }
  }

  @override
  Future<Result<void>> save(Task task) async {
    try {
      final strings = List<String>.from(_prefs.getStringList(_key) ?? []);
      final model = TaskModel.fromEntity(task);
      strings.add(model.toJson());
      final ok = await _prefs.setStringList(_key, strings);
      if (!ok) {
        AppLogger.warning('Failed to persist task: setStringList returned false');
        return const Error(CacheFailure('Не удалось сохранить задачу'));
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to save task to local storage', e, st);
      return const Error(CacheFailure('Не удалось сохранить задачу'));
    }
  }

  @override
  Future<Result<void>> update(Task task) async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(TaskModel.fromJson);
      final model = TaskModel.fromEntity(task);
      final updated = current
          .map((t) => t.id == task.id ? model.toJson() : TaskModel.fromEntity(t).toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        AppLogger.warning('Failed to update task: setStringList returned false');
        return const Error(CacheFailure('Не удалось обновить задачу'));
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to update task in local storage', e, st);
      return const Error(CacheFailure('Не удалось обновить задачу'));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(TaskModel.fromJson);
      final updated = current
          .where((t) => t.id != id)
          .map((t) => TaskModel.fromEntity(t).toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        AppLogger.warning('Failed to delete task: setStringList returned false');
        return const Error(CacheFailure('Не удалось удалить задачу'));
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to delete task from local storage', e, st);
      return const Error(CacheFailure('Не удалось удалить задачу'));
    }
  }

  @override
  Future<Result<void>> deleteCompleted() async {
    try {
      final current = (_prefs.getStringList(_key) ?? []).map(TaskModel.fromJson);
      final updated = current
          .where((t) => !t.isCompleted)
          .map((t) => TaskModel.fromEntity(t).toJson())
          .toList();
      final ok = await _prefs.setStringList(_key, updated);
      if (!ok) {
        AppLogger.warning('Failed to clear completed tasks: setStringList returned false');
        return const Error(
          CacheFailure('Не удалось очистить выполненные задачи'),
        );
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to clear completed tasks from local storage', e, st);
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
      final ok = await _prefs.setStringList(_categoriesKey, categories);
      if (!ok) {
        AppLogger.warning('Failed to save categories: setStringList returned false');
        return const Error(CacheFailure('Не удалось сохранить категории'));
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to save categories', e, st);
      return const Error(CacheFailure('Не удалось сохранить категории'));
    }
  }

  @override
  Map<String, TaskCategoryStyle> getCategoryStyles() {
    final rawList = _prefs.getStringList(_categoryStylesKey);
    final result = <String, TaskCategoryStyle>{};
    if (rawList != null) {
      for (final item in rawList) {
        try {
          final style = TaskCategoryStyle.fromJson(item);
          result[style.name.toLowerCase()] = style;
        } catch (e, st) {
          AppLogger.warning('Corrupted category style entry skipped: $item', e, st);
        }
      }
    }
    return result;
  }

  @override
  Future<Result<void>> saveCategoryStyles(
    Map<String, TaskCategoryStyle> styles,
  ) async {
    try {
      final list = styles.values.map((s) => s.toJson()).toList();
      final ok = await _prefs.setStringList(_categoryStylesKey, list);
      if (!ok) {
        AppLogger.warning('Failed to save category styles: setStringList returned false');
        return const Error(CacheFailure('Не удалось сохранить стиль категории'));
      }
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Failed to save category styles', e, st);
      return const Error(CacheFailure('Не удалось сохранить стиль категории'));
    }
  }
}
