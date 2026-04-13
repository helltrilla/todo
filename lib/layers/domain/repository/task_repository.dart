import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/layers/domain/entity/task.dart';

class TaskRepository {
  static const key = "tasks";
  
  Future<void> getTasks() async {
    final List<String>? taskStrings = await SharedPreferencesAsync()
        .getStringList("tasks");
    if (taskStrings != null) {
    }
  }

  Future<void> save(Task task) {
    // TODO: implement save
    throw UnimplementedError();
  }

  Future<void> del(int id) async {
    final List<String>? taskStrings = await SharedPreferencesAsync().getStringList("tasks");
    // tasks.removeAt(id);
    // List<String> strList = tasks.map((task) => task.toJson()).toList();
    // SharedPreferencesAsync().setStringList(key, strList);
  }
}