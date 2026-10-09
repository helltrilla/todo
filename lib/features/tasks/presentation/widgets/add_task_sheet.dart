import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/core/localization/app_localizations.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
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
  final TextEditingController _subtaskController = TextEditingController();
  DateTime? _selectedDate;
  int? _reminderOffsetMinutes = 15;
  int _priorityIndex = -1;
  String _selectedCategory = TaskController.globalCategory;
  bool _isCompleted = false;
  bool _isPinned = false;
  late List<SubTask> _subtasks;
  RecurrenceRule _recurrence = RecurrenceRule.none;

  bool _showAiInput = false;
  bool _isAiParsing = false;
  String? _aiFeedbackMessage;
  final TextEditingController _aiPromptController = TextEditingController();

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialTask;
    if (existing != null) {
      _nameController = TextEditingController(text: existing.name);
      _descController = TextEditingController(text: existing.value);
      _selectedDate = existing.dueDate;
      _reminderOffsetMinutes = existing.reminderOffsetMinutes;
      _priorityIndex = existing.priorityIndex;
      _selectedCategory = existing.category;
      _isCompleted = existing.isCompleted;
      _isPinned = existing.isPinned;
      _subtasks = List<SubTask>.from(existing.subtasks);
      _recurrence = existing.recurrence;
    } else {
      _nameController = TextEditingController();
      _descController = TextEditingController();
      _subtasks = <SubTask>[];
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
    _aiPromptController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _parseWithAi() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) return;
    AppHaptics.selection();
    setState(() {
      _isAiParsing = true;
      _aiFeedbackMessage = null;
    });

    final taskController = context.read<TaskController>();
    final parser = context.read<ISmartTaskParser>();

    final result = await parser.parseTaskPrompt(
      prompt,
      referenceTime: DateTime.now(),
      availableCategories: taskController.categories,
    );

    if (!mounted) return;

    if (result is Success<SmartTaskDraft>) {
      final draft = result.data;
      AppHaptics.heavy();
      setState(() {
        _isAiParsing = false;
        if (draft.name.isNotEmpty) {
          _nameController.text = draft.name;
        }
        if (draft.description.isNotEmpty) {
          _descController.text = draft.description;
        }
        if (draft.dueDate != null) {
          _selectedDate = draft.dueDate;
        }
        if (draft.reminderOffsetMinutes != null) {
          _reminderOffsetMinutes = draft.reminderOffsetMinutes;
        }
        if (draft.priorityIndex >= 0 && draft.priorityIndex <= 3) {
          _priorityIndex = draft.priorityIndex;
        }
        if (draft.category != null && draft.category!.isNotEmpty) {
          _selectedCategory = draft.category!;
        }
        if (draft.subtasks.isNotEmpty) {
          final nowMicro = DateTime.now().microsecondsSinceEpoch;
          _subtasks = draft.subtasks.asMap().entries.map((entry) {
            return SubTask(
              id: nowMicro + entry.key,
              title: entry.value,
              isCompleted: false,
            );
          }).toList();
        }
        _showAiInput = false;
        _aiFeedbackMessage = context.tr.aiSuccess;
      });
    } else if (result is Error<SmartTaskDraft>) {
      AppHaptics.light();
      setState(() {
        _isAiParsing = false;
        _aiFeedbackMessage = result.failure.message;
      });
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks = [
        ..._subtasks,
        SubTask(id: DateTime.now().microsecondsSinceEpoch, title: text),
      ];
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(int id) {
    setState(() {
      _subtasks = _subtasks.map((s) {
        if (s.id == id) return s.copyWith(isCompleted: !s.isCompleted);
        return s;
      }).toList();
    });
  }

  void _removeSubtask(int id) {
    setState(() {
      _subtasks = _subtasks.where((s) => s.id != id).toList();
    });
  }

  Future<void> _pickDate() async {
    int? chosenReminder = _reminderOffsetMinutes;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => ListodoCalendarDialog(
        initialDate: _selectedDate,
        initialReminderMinutes: _reminderOffsetMinutes,
        onReminderChanged: (minutes) {
          chosenReminder = minutes;
        },
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _reminderOffsetMinutes = chosenReminder;
      });
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

  Future<void> _pickRecurrence() async {
    AppHaptics.selection();
    final picked = await showDialog<RecurrenceRule>(
      context: context,
      builder: (_) => _RecurrencePickerDialog(initialRule: _recurrence),
    );
    if (picked != null) {
      setState(() {
        _recurrence = picked;
        if (picked.isRepeating && _selectedDate == null) {
          final now = DateTime.now();
          _selectedDate = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
          );
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

    // Automatically append any unsubmitted text in the subtask input field
    if (_subtaskController.text.trim().isNotEmpty) {
      _addSubtask();
    }

    final controller = context.read<TaskController>();
    final existing = widget.initialTask;

    if (existing != null) {
      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        value: _descController.text.trim(),
        dueDate: _selectedDate,
        clearDueDate: _selectedDate == null,
        reminderOffsetMinutes: _selectedDate != null
            ? _reminderOffsetMinutes
            : null,
        clearReminder: _selectedDate == null || _reminderOffsetMinutes == null,
        priorityIndex: _priorityIndex,
        isCompleted: _isCompleted,
        isPinned: _isPinned,
        category: _selectedCategory,
        subtasks: _subtasks,
        recurrence: _recurrence,
      );
      await controller.updateTask(updated);
    } else {
      await controller.add(
        name: _nameController.text.trim(),
        value: _descController.text.trim(),
        dueDate: _selectedDate,
        reminderOffsetMinutes: _selectedDate != null
            ? _reminderOffsetMinutes
            : null,
        priorityIndex: _priorityIndex,
        isPinned: _isPinned,
        category: _selectedCategory,
        subtasks: _subtasks,
        recurrence: _recurrence,
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final userCategories = taskController.categories;
    final sheetCategories = <String>[
      TaskController.globalCategory,
      ...userCategories,
    ];
    final hasPriority = _priorityIndex != -1;
    final priority = hasPriority
        ? PriorityLevel.fromIndex(_priorityIndex)
        : null;

    return SingleChildScrollView(
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
          if (!_isEditing) ...[
            const SizedBox(height: 8),
            _buildAiSection(context),
          ],
          if (_aiFeedbackMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3ECF8E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3ECF8E).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF3ECF8E),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _aiFeedbackMessage!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _aiFeedbackMessage = null),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.labeltext,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

          // Subtasks Checklist Builder
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subtaskController,
                  onSubmitted: (_) => _addSubtask(),
                  style: const TextStyle(
                    color: AppColors.maintext,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(),
                    hintText: 'Добавить подзадачу (шаг чек-листа)...',
                    hintStyle: TextStyle(
                      color: AppColors.labeltext,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Добавить шаг',
                onPressed: _addSubtask,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.cardBg,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(
                  Icons.add_task_rounded,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
              ),
            ],
          ),
          if (_subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._subtasks.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleSubtask(sub.id),
                        child: Icon(
                          sub.isCompleted
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: sub.isCompleted
                              ? AppColors.accentYellow
                              : AppColors.labeltext,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.title,
                          style: TextStyle(
                            color: sub.isCompleted
                                ? AppColors.labeltext
                                : AppColors.maintext,
                            fontSize: 13,
                            decoration: sub.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeSubtask(sub.id),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.labeltext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sheetCategories.map((cat) {
                final isGlobal = cat == TaskController.globalCategory;
                final isSelected = _selectedCategory == cat;
                final style = isGlobal
                    ? null
                    : taskController.styleForCategory(cat);
                final chipColor = isGlobal ? AppColors.active : style!.color;

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
                            ? chipColor
                            : chipColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? chipColor
                              : chipColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGlobal ? Icons.public_rounded : style!.icon,
                            size: 14,
                            color: isSelected
                                ? (isGlobal ? Colors.white : Colors.black)
                                : chipColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isGlobal ? 'Общее (Во всех)' : cat,
                            style: TextStyle(
                              color: isSelected
                                  ? (isGlobal ? Colors.white : Colors.black)
                                  : AppColors.maintext,
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
          if ((hasPriority && priority != null) || _recurrence.isRepeating) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasPriority && priority != null)
                  _PriorityChip(
                    priority: priority,
                    onClear: () => setState(() => _priorityIndex = -1),
                  ),
                if (_recurrence.isRepeating)
                  _RecurrenceChip(
                    recurrence: _recurrence,
                    onTap: _pickRecurrence,
                    onClear: () =>
                        setState(() => _recurrence = RecurrenceRule.none),
                  ),
              ],
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
                Flexible(
                  child: _DateChip(
                    date: _selectedDate!,
                    reminderOffsetMinutes: _reminderOffsetMinutes,
                    onTap: _pickDate,
                    onClear: () => setState(() => _selectedDate = null),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Повторение задачи',
                icon: Icon(
                  Icons.repeat_rounded,
                  color: _recurrence.isRepeating
                      ? AppColors.accentYellow
                      : AppColors.icons,
                ),
                onPressed: _pickRecurrence,
              ),
              IconButton(
                tooltip: 'Закрепить наверху',
                icon: Icon(
                  _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  color: _isPinned ? AppColors.accentYellow : AppColors.icons,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  setState(() => _isPinned = !_isPinned);
                },
              ),
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

  Widget _buildAiSection(BuildContext context) {
    final tr = context.tr;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showAiInput
              ? const Color(0xFF8687E7).withValues(alpha: 0.5)
              : const Color(0xFF8687E7).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.selection();
                setState(() => _showAiInput = !_showAiInput);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8687E7), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.aiSmartCreate,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Напишите всё подряд — ИИ разложит по полочкам',
                            style: TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _showAiInput
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.labeltext,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showAiInput) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiPromptController,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                      color: AppColors.maintext,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: tr.aiPromptPlaceholder,
                      hintStyle: const TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.bgmain,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _aiSampleChip(
                        '🦷 Стоматолог завтра в 15:00, снимок и полис, срочно',
                      ),
                      _aiSampleChip(
                        '🏋️ Тренировка завтра в 19:00: форма, вода, шейкер',
                      ),
                      _aiSampleChip(
                        '🛒 Купить: молоко, яйца, сыр и кофе, высокий приоритет',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isAiParsing ? null : _parseWithAi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8687E7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: _isAiParsing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isAiParsing ? tr.aiParsing : tr.aiParseButton,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiSampleChip(String sampleText) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        _aiPromptController.text = sampleText;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          sampleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.labeltext,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.recurrence,
    required this.onTap,
    required this.onClear,
  });

  final RecurrenceRule recurrence;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentYellow.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentYellow.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.repeat_rounded,
              color: AppColors.accentYellow,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              recurrence.shortLabel,
              style: const TextStyle(
                color: AppColors.accentYellow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.accentYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrencePickerDialog extends StatelessWidget {
  const _RecurrencePickerDialog({required this.initialRule});

  final RecurrenceRule initialRule;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  color: AppColors.accentYellow,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Повторение задачи',
                  style: TextStyle(
                    color: AppColors.maintext,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...RecurrenceRule.values.map((rule) {
              final selected = rule == initialRule;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(context).pop(rule);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.active.withValues(alpha: 0.22)
                          : AppColors.bgmain,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentYellow
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          rule == RecurrenceRule.none
                              ? Icons.block_rounded
                              : Icons.repeat_rounded,
                          size: 18,
                          color: selected
                              ? AppColors.accentYellow
                              : AppColors.labeltext,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rule.label,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.white
                                  : AppColors.maintext,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accentYellow,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
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
  const _DateChip({
    required this.date,
    required this.reminderOffsetMinutes,
    required this.onTap,
    required this.onClear,
  });
  final DateTime date;
  final int? reminderOffsetMinutes;
  final VoidCallback onTap;
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
    final reminderText =
        reminderOffsetMinutes != null && reminderOffsetMinutes! > 0
        ? Task.formatReminderOffset(reminderOffsetMinutes!)
        : 'В момент';
    final label = '${date.day} ${months[date.month - 1]} • $hh:$mm';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgmain,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.maintext, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.notifications_active_outlined,
              size: 12,
              color: AppColors.accentYellow,
            ),
            const SizedBox(width: 3),
            Text(
              reminderText,
              style: const TextStyle(
                color: AppColors.accentYellow,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
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
      ),
    );
  }
}
