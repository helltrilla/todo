import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Displays a single task row with swipe-to-delete support.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onDelete});

  final Task task;
  final VoidCallback onDelete;

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
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _PriorityIcon(task: task),
            const SizedBox(width: 12),
            Expanded(child: _TaskInfo(task: task)),
            if (task.hasPriority) _PriorityBadge(task: task),
          ],
        ),
      ),
    );
  }
}

class _PriorityIcon extends StatelessWidget {
  const _PriorityIcon({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: task.priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(task.priority.icon, color: task.priority.color, size: 28),
    );
  }
}

class _TaskInfo extends StatelessWidget {
  const _TaskInfo({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.name,
          style: const TextStyle(
            color: AppColors.maintext,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (task.value.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.value,
            style: TextStyle(
              color: AppColors.maintext.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
        if (task.dueDate != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatDate(task.dueDate!),
            style: TextStyle(
              color: AppColors.maintext.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: task.priority.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: task.priority.color),
      ),
      child: Text(
        task.priority.label,
        style: TextStyle(
          color: task.priority.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
