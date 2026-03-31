import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/layers/data/datesource/local/task/task_local_datasource.dart';
import 'package:todo/layers/domain/entity/task.dart';

class TaskSharedPrefLocalDatasource implements TaskLocalDatasource {
  final String key = "tasks";
  final _prefs = SharedPreferences.getInstance();

  @override
  Future<void> del(int id) {
    // TODO: implement del
    throw UnimplementedError();
  }

  @override
  Future<List<Task>> getAll() async {
    final pref = await _prefs;
    final List<String> strList = pref.getStringList(key) ?? [];
    return strList.map((e) => Task.fromJson(jsonDecode(e))).toList();
  }

  @override
  Future<void> save() async {
    final pref = await _prefs;

    // pref.setStringList(key, value);
  }
}
