import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/priority_picker_dialog.dart';

/// Bottom sheet for creating a new task.
/// Delegates persistence to [TaskController].
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  int _priorityIndex = -1;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickPriority() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => PriorityPickerDialog(initialIndex: _priorityIndex),
    );
    if (result != null) setState(() => _priorityIndex = result);
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введи хотя бы название задачи')),
      );
      return;
    }

    await context.read<TaskController>().add(
      name: _nameController.text.trim(),
      value: _descController.text.trim(),
      dueDate: _selectedDate,
      priorityIndex: _priorityIndex,
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasPriority = _priorityIndex != -1;
    final priority = hasPriority
        ? PriorityLevel.fromIndex(_priorityIndex)
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 30,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.maintext,
            ),
          ),
          const SizedBox(height: 12),
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
          if (hasPriority && priority != null) ...[
            const SizedBox(height: 10),
            _PriorityChip(priority: priority),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                color: AppColors.icons,
                onPressed: _pickDate,
              ),
              if (_selectedDate != null) _DateChip(date: _selectedDate!),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  Icons.flag,
                  color: hasPriority ? priority!.color : AppColors.icons,
                ),
                onPressed: _pickPriority,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.send),
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
  const _PriorityChip({required this.priority});
  final PriorityLevel priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priority.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, color: priority.color),
          const SizedBox(width: 8),
          Text(priority.label, style: TextStyle(color: priority.color)),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
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
    final label = '${date.day} ${months[date.month - 1]} ${date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.maintext, fontSize: 10),
      ),
    );
  }
}
