import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final Task task;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(task.name, style: TextStyle(color: AppColors.maintext)),
          Text(task.value, style: TextStyle(color: AppColors.maintext)),
          if (task.duedate != null)
          Text('когда: ${_formatDate(task.duedate!)}', style: TextStyle(color: AppColors.maintext),)
        ],
      ),
    );
  }
}
  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }