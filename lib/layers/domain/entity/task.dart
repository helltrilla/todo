import 'dart:convert';
import 'package:todo/layers/domain/entity/priority_level.dart';

class Task {
  final int id;
  final String name;
  final String value;
  final DateTime createAt;
  final DateTime? duedate;
  final int priorityIndex;

  Task({
    required this.id,
    required this.name,
    required this.createAt,
    required this.value,
    required this.duedate,
    required this.priorityIndex,
  });
  
  PriorityLevel get priority => PriorityLevel.fromIndex(priorityIndex);
  



  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'value': value,
      'createAt': createAt.millisecondsSinceEpoch,
      'duedate': duedate?.millisecondsSinceEpoch,
      'priorityIndex': priorityIndex,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      name: map['name'] as String,
      value: map['value'] as String,
      createAt: DateTime.fromMillisecondsSinceEpoch(map['createAt'] as int),
      duedate: map['duedate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['duedate'] as int) 
          : null,
      priorityIndex: map['priorityIndex'] as int? ?? -1,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);
  
  static int get defaultPriorityIndex => -1;
  
  bool get hasPriority => priorityIndex != -1;
  
  @override
  String toString() {
    return 'Task(id: $id, name: $name, value: $value, createAt: $createAt, duedate: $duedate, priorityIndex: $priorityIndex)';
  }
}