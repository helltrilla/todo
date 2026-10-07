import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/repositories/i_task_repository.dart';

/// Persists tasks as JSON strings in SharedPreferences.
///
/// [prefs] is pre-initialized and injected at the app root — no async
/// getInstance() on every read/write operation.
class TaskLocalRepository implements ITaskRepository {
  TaskLocalRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'tasks';

  @override
  Future<List<Task>> getAll() async {
    final strings = _prefs.getStringList(_key) ?? [];
    return strings.map(Task.fromJson).toList();
  }

  @override
  Future<void> save(Task task) async {
    final strings = List<String>.from(_prefs.getStringList(_key) ?? []);
    strings.add(task.toJson());
    await _prefs.setStringList(_key, strings);
  }

  @override
  Future<void> delete(int id) async {
    final current = (_prefs.getStringList(_key) ?? []).map(Task.fromJson);
    final updated = current
        .where((t) => t.id != id)
        .map((t) => t.toJson())
        .toList();
    await _prefs.setStringList(_key, updated);
  }
}
