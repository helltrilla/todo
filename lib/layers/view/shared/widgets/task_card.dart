import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/layers/domain/entity/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onDelete});
  
  final Task task;
  final VoidCallback? onDelete;
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart, 
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: task.priority.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.priority.icon,
                color: task.priority.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      color: AppColors.maintext,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.value,
                    style: TextStyle(
                      color: AppColors.maintext.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (task.duedate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'когда: ${_formatDate(task.duedate!)}',
                      style: TextStyle(
                        color: AppColors.maintext.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.hasPriority)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: task.priority.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.priority.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(
                    color: task.priority.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

      // return Container(
    //   child: Column(
    //     children: [
    //       Text(task.name, style: TextStyle(color: AppColors.maintext)),
    //       Text(task.value, style: TextStyle(color: AppColors.maintext)),
    //       if (task.duedate != null)
    //       Text('когда: ${_formatDate(task.duedate!)}', style: TextStyle(color: AppColors.maintext),)
    //     ],
    //   ),
    // );