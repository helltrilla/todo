import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/listodo_calendar_dialog.dart';
import 'package:todo/features/tasks/presentation/widgets/priority_picker_dialog.dart';

/// Bottom sheet for creating a new task or editing an existing [initialTask].
/// Includes the special 'Общее' (Global) category that pins the task across all categories.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.initialTask});

  final Task? initialTask;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  DateTime? _selectedDate;
  int _priorityIndex = -1;
  String _selectedCategory = TaskController.globalCategory;
  bool _isCompleted = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialTask;
    if (existing != null) {
      _nameController = TextEditingController(text: existing.name);
      _descController = TextEditingController(text: existing.value);
      _selectedDate = existing.dueDate;
      _priorityIndex = existing.priorityIndex;
      _selectedCategory = existing.category;
      _isCompleted = existing.isCompleted;
    } else {
      _nameController = TextEditingController();
      _descController = TextEditingController();
      final controller = context.read<TaskController>();
      if (controller.selectedCategory != TaskController.allCategory) {
        _selectedCategory = controller.selectedCategory;
      } else {
        _selectedCategory = TaskController.globalCategory;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => ListodoCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickPriority() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => PriorityPickerDialog(initialIndex: _priorityIndex),
    );
    if (result != null) {
      setState(() {
        _priorityIndex = result;
        // When selecting P1 (Critical / Срочно), automatically switch to
        // 'Общее' so the urgent task shines across all categories.
        if (result == 0) {
          _selectedCategory = TaskController.globalCategory;
        }
      });
    }
  }

  Future<void> _deleteTask() async {
    final existing = widget.initialTask;
    if (existing == null) return;
    await context.read<TaskController>().delete(existing.id);
    if (mounted) context.pop();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введи хотя бы название задачи')),
      );
      return;
    }

    final controller = context.read<TaskController>();
    final existing = widget.initialTask;

    if (existing != null) {
      final updated = Task(
        id: existing.id,
        name: _nameController.text.trim(),
        value: _descController.text.trim(),
        createdAt: existing.createdAt,
        dueDate: _selectedDate,
        priorityIndex: _priorityIndex,
        isCompleted: _isCompleted,
        category: _selectedCategory,
      );
      await controller.updateTask(updated);
    } else {
      await controller.add(
        name: _nameController.text.trim(),
        value: _descController.text.trim(),
        dueDate: _selectedDate,
        priorityIndex: _priorityIndex,
        category: _selectedCategory,
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final userCategories = context.watch<TaskController>().categories;
    final sheetCategories = <String>[
      TaskController.globalCategory,
      ...userCategories,
    ];
    final hasPriority = _priorityIndex != -1;
    final priority = hasPriority
        ? PriorityLevel.fromIndex(_priorityIndex)
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit task' : 'Add task',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.maintext,
                ),
              ),
              if (_isEditing)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isCompleted = !_isCompleted),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? AppColors.active.withValues(alpha: 0.2)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isCompleted
                                ? AppColors.active
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 15,
                              color: _isCompleted
                                  ? AppColors.active
                                  : AppColors.labeltext,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isCompleted ? 'Выполнено' : 'В работе',
                              style: TextStyle(
                                color: _isCompleted
                                    ? AppColors.white
                                    : AppColors.labeltext,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Удалить задачу',
                      onPressed: _deleteTask,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.maintext),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Task',
              labelStyle: TextStyle(color: AppColors.labeltext, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: AppColors.maintext),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Description',
              labelStyle: TextStyle(color: AppColors.labeltext, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sheetCategories.map((cat) {
                final isGlobal = cat == TaskController.globalCategory;
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isGlobal
                                  ? AppColors.active
                                  : AppColors.accentYellow)
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? (isGlobal
                                    ? AppColors.active
                                    : AppColors.accentYellow)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isGlobal) ...[
                            Icon(
                              Icons.public_rounded,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.accentYellow,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isGlobal ? 'Общее (Во всех)' : cat,
                            style: TextStyle(
                              color: isSelected
                                  ? (isGlobal ? Colors.white : Colors.black)
                                  : AppColors.labeltext,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (hasPriority && priority != null) ...[
            const SizedBox(height: 10),
            _PriorityChip(
              priority: priority,
              onClear: () => setState(() => _priorityIndex = -1),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                color: _selectedDate != null
                    ? AppColors.accentYellow
                    : AppColors.icons,
                onPressed: _pickDate,
              ),
              if (_selectedDate != null)
                _DateChip(
                  date: _selectedDate!,
                  onClear: () => setState(() => _selectedDate = null),
                ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  hasPriority ? priority!.icon : Icons.flag_outlined,
                  color: hasPriority ? priority!.color : AppColors.icons,
                ),
                onPressed: _pickPriority,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isEditing ? Icons.check_circle : Icons.send),
                color: AppColors.active,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority, required this.onClear});
  final PriorityLevel priority;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: priority.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, color: priority.color, size: 16),
          const SizedBox(width: 6),
          Text(
            'Приоритет ${priority.label}',
            style: TextStyle(color: priority.color, fontSize: 12),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 14, color: priority.color),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onClear});
  final DateTime date;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final label = '${date.day} ${months[date.month - 1]} • $hh:$mm';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.maintext, fontSize: 11),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.labeltext,
            ),
          ),
        ],
      ),
    );
  }
}
