import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo/layers/domain/entity/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final Task task;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(task.name, style: TextStyle(color: Colors.white)),
          Text(task.value, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
