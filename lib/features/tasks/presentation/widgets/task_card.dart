import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Displays a single clickable task card styled after the Listodo UI Kit:
/// - Tapping the card opens the edit sheet (`onTap`)
/// - Left: circular completion checkbox (`onToggleComplete`)
/// - Center: task title, optional description, formatted date & time, and category
/// - Right: colored priority flag icon
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onDelete,
    this.confirmDismiss,
    this.onToggleComplete,
    this.onTap,
  });

  final Task task;
  final VoidCallback onDelete;
  final Future<bool?> Function()? confirmDismiss;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<int>(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: confirmDismiss != null ? (_) => confirmDismiss!() : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _CompletionCheckbox(
                  isCompleted: task.isCompleted,
                  onTap: onToggleComplete,
                ),
                const SizedBox(width: 14),
                Expanded(child: _TaskInfo(task: task)),
                const SizedBox(width: 12),
                _PriorityFlag(task: task),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({required this.isCompleted, this.onTap});

  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.active : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppColors.active : Colors.white38,
            width: 1.8,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

class _TaskInfo extends StatelessWidget {
  const _TaskInfo({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final displayDate = task.dueDate ?? task.createdAt;
    final showTime = task.dueDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.name,
          style: TextStyle(
            color: task.isCompleted ? AppColors.labeltext : AppColors.maintext,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.labeltext,
          ),
        ),
        if (task.value.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.value,
            style: TextStyle(
              color: AppColors.maintext.withValues(alpha: 0.65),
              fontSize: 13,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _formatDate(displayDate, includeTime: showTime),
              style: const TextStyle(color: AppColors.labeltext, fontSize: 12),
            ),
            if (task.category.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.category,
                  style: const TextStyle(
                    color: AppColors.labeltext,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date, {required bool includeTime}) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'June',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    final base = '${date.day} ${months[date.month - 1]}, ${date.year}';
    if (!includeTime) return base;
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$base • $hh:$mm';
  }
}

class _PriorityFlag extends StatelessWidget {
  const _PriorityFlag({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final flagColor = task.hasPriority
        ? task.priority.color
        : const Color(0xFFFF5252);

    return Icon(Icons.flag_rounded, color: flagColor, size: 22);
  }
}
