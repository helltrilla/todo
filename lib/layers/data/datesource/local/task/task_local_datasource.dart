import 'package:todo/layers/domain/entity/task.dart';

abstract class TaskLocalDatasource {
  Future<List<Task>> getAll();
  Future<void> save();
  Future<void> del(int id);
}
