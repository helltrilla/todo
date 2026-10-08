import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Displays a single clickable task card styled after the Listodo UI Kit:
/// - Left accent bar & border tinted by task priority
/// - Left: circular completion checkbox (`onToggleComplete`)
/// - Center: task title, optional description, formatted date & time, and category
/// - Right: expressive priority badge with icon and label
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
    final priority = task.priority;
    final isUrgent =
        !task.isCompleted && task.hasPriority && priority == PriorityLevel.p1;

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUrgent
                ? priority.color.withValues(alpha: 0.5)
                : (task.hasPriority && !task.isCompleted
                      ? priority.color.withValues(alpha: 0.2)
                      : Colors.transparent),
            width: isUrgent ? 1.4 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (task.hasPriority) ...[
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? priority.color.withValues(alpha: 0.35)
                          : priority.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                _CompletionCheckbox(
                  isCompleted: task.isCompleted,
                  accentColor: task.hasPriority
                      ? priority.color
                      : AppColors.active,
                  onTap: onToggleComplete,
                ),
                const SizedBox(width: 12),
                Expanded(child: _TaskInfo(task: task)),
                const SizedBox(width: 10),
                _PriorityBadge(task: task),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({
    required this.isCompleted,
    required this.accentColor,
    this.onTap,
  });

  final bool isCompleted;
  final Color accentColor;
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
          color: isCompleted ? accentColor : Colors.transparent,
          border: Border.all(
            color: isCompleted ? accentColor : Colors.white38,
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
            fontWeight: FontWeight.w600,
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
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _formatDate(displayDate, includeTime: showTime),
              style: const TextStyle(color: AppColors.labeltext, fontSize: 12),
            ),
            if (task.category.isNotEmpty) _CategoryTag(category: task.category),
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

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final priority = task.priority;
    if (!task.hasPriority) {
      return Icon(
        priority.icon,
        color: Colors.white.withValues(alpha: 0.25),
        size: 20,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: priority.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, color: priority.color, size: 15),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final isGlobal =
        category.toLowerCase() == 'общее' ||
        category.toLowerCase() == 'all task';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isGlobal
            ? AppColors.active.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: isGlobal
            ? Border.all(color: AppColors.active.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGlobal) ...[
            const Icon(
              Icons.public_rounded,
              size: 11,
              color: AppColors.accentYellow,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isGlobal ? 'Общее' : category,
            style: TextStyle(
              color: isGlobal ? AppColors.maintext : AppColors.labeltext,
              fontSize: 10,
              fontWeight: isGlobal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
