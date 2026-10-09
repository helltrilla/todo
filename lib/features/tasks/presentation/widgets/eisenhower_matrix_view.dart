import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

class EisenhowerMatrixView extends StatelessWidget {
  const EisenhowerMatrixView({
    super.key,
    required this.onEditTask,
  });

  final ValueChanged<Task> onEditTask;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _QuadrantBox(
                      quadrant: EisenhowerQuadrant.q1,
                      onEditTask: onEditTask,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuadrantBox(
                      quadrant: EisenhowerQuadrant.q2,
                      onEditTask: onEditTask,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _QuadrantBox(
                      quadrant: EisenhowerQuadrant.q3,
                      onEditTask: onEditTask,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuadrantBox(
                      quadrant: EisenhowerQuadrant.q4,
                      onEditTask: onEditTask,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuadrantBox extends StatefulWidget {
  const _QuadrantBox({
    required this.quadrant,
    required this.onEditTask,
  });

  final EisenhowerQuadrant quadrant;
  final ValueChanged<Task> onEditTask;

  @override
  State<_QuadrantBox> createState() => _QuadrantBoxState();
}

class _QuadrantBoxState extends State<_QuadrantBox> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final tasks = controller.tasksForQuadrant(widget.quadrant);
    final q = widget.quadrant;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.quadrant != q,
      onAcceptWithDetails: (details) async {
        setState(() => _isDragOver = false);
        AppHaptics.heavy();
        final movedTask = details.data;
        await controller.moveTaskToQuadrant(movedTask, q);
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text('«${movedTask.name}» перемещена в «${q.title}»'),
              backgroundColor: const Color(0xFF242432),
              action: SnackBarAction(
                label: 'Отмена',
                textColor: q.color,
                onPressed: () {
                  controller.moveTaskToQuadrant(movedTask, movedTask.quadrant);
                },
              ),
            ),
          );
        }
      },
      onMove: (_) {
        if (!_isDragOver) setState(() => _isDragOver = true);
      },
      onLeave: (_) {
        if (_isDragOver) setState(() => _isDragOver = false);
      },
      builder: (context, candidateData, rejectedData) {
        final isActiveGlow = _isDragOver || candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActiveGlow
                ? q.accentColor.withValues(alpha: 0.45)
                : const Color(0xFF1B1B22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActiveGlow ? q.color : q.color.withValues(alpha: 0.3),
              width: isActiveGlow ? 2.0 : 1.2,
            ),
            boxShadow: isActiveGlow
                ? [
                    BoxShadow(
                      color: q.color.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quadrant Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: q.color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(q.icon, color: q.color, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: TextStyle(
                              color: q.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            q.actionLabel,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // Tasks Content
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          isActiveGlow
                              ? 'Отпустите здесь'
                              : 'Перетащите сюда',
                          style: TextStyle(
                            color: isActiveGlow
                                ? q.color
                                : Colors.white.withValues(alpha: 0.25),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _DraggableTaskItem(
                            task: task,
                            quadrantColor: q.color,
                            onEdit: () => widget.onEditTask(task),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableTaskItem extends StatelessWidget {
  const _DraggableTaskItem({
    required this.task,
    required this.quadrantColor,
    required this.onEdit,
  });

  final Task task;
  final Color quadrantColor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TaskController>();

    return LongPressDraggable<Task>(
      data: task,
      delay: const Duration(milliseconds: 180),
      onDragStarted: () => AppHaptics.heavy(),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: 170,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF282836),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: quadrantColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              task.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white24,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF24242F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: task.isCompleted
                  ? Colors.white10
                  : quadrantColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              // Checkbox Toggle
              InkWell(
                onTap: () {
                  AppHaptics.selection();
                  controller.toggleCompleted(task.id);
                },
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppColors.primary
                          : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),

              // Title
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    color: task.isCompleted
                        ? Colors.white38
                        : AppColors.maintext,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '${task.completedSubtasksCount}/${task.subtasks.length}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
