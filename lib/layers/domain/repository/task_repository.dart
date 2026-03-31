import 'package:todo/layers/domain/entity/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<void> save(Task task);
  Future<void> del(int id);
}
