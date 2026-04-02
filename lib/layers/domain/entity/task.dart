import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Task {
  final int id;
  final String name;
  final String value;
  final DateTime createAt;
  final DateTime? duedate;

  Task({
    required this.id,
    required this.name,
    required this.createAt,
    required this.value,
    required this.duedate,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'value': value,
      'createAt': createAt.millisecondsSinceEpoch,
      'duedate': duedate?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      name: map['name'] as String,
      value: map['value'] as String,
      createAt: DateTime.fromMillisecondsSinceEpoch(map['createAt'] as int),
      duedate: map['duedate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['duedate'] as int) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);
}
