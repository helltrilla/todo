import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/tasks/presentation/widgets/task_card.dart';

/// Listodo Calendar tab view with horizontal day strip and Active/Completed toggle.
class CalendarTabView extends StatefulWidget {
  const CalendarTabView({
    super.key,
    required this.confirmDismiss,
    required this.onEditTask,
  });

  final Future<bool?> Function(Task) confirmDismiss;
  final void Function(Task) onEditTask;

  @override
  State<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends State<CalendarTabView> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  bool _showCompleted = false;

  static const _monthNames = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static const _weekdayShort = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      final daysInNewMonth = DateUtils.getDaysInMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );
      final clampedDay = _selectedDate.day.clamp(1, daysInNewMonth);
      _selectedDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        clampedDay,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final tasks = controller.tasksForDate(
      _selectedDate,
      completed: _showCompleted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month switcher & Horizontal day strip card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _changeMonth(-1),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.icons,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _monthNames[_visibleMonth.month - 1].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.maintext,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          '${_visibleMonth.year}',
                          style: TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _changeMonth(1),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.icons,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final date = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      day,
                    );
                    final isSelected =
                        date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    final weekday = _weekdayShort[date.weekday - 1];
                    final isWeekend = date.weekday == 6 || date.weekday == 7;
                    final hasTasks = controller.hasTasksOnDate(date);

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.active : AppColors.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentYellow
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekday,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : (isWeekend
                                            ? const Color(0xFFFF6B6B)
                                            : AppColors.labeltext),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: AppColors.maintext,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasTasks
                                      ? (isSelected
                                            ? AppColors.accentYellow
                                            : AppColors.active)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Segmented toggle: Today (Active) vs Completed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompleted = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_showCompleted
                            ? AppColors.active
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'На этот день',
                        style: TextStyle(
                          color: !_showCompleted
                              ? AppColors.white
                              : AppColors.labeltext,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompleted = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _showCompleted
                            ? AppColors.active
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Выполненные',
                        style: TextStyle(
                          color: _showCompleted
                              ? AppColors.white
                              : AppColors.labeltext,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Filtered task list for the selected date
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 64,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showCompleted
                              ? 'Нет выполненных задач за этот день'
                              : 'На выбранный день задач нет',
                          style: TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          confirmDismiss: () => widget.confirmDismiss(task),
                          onDelete: () => controller.delete(task.id),
                          onArchive: () {
                            controller.archiveTask(task.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '«${task.name}» перемещена в архив профиля',
                                ),
                                action: SnackBarAction(
                                  label: 'Вернуть',
                                  textColor: AppColors.accentYellow,
                                  onPressed: () =>
                                      controller.unarchiveTask(task.id),
                                ),
                              ),
                            );
                          },
                          onToggleComplete: () =>
                              controller.toggleCompleted(task.id),
                          onTap: () => widget.onEditTask(task),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
