import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';

/// Custom dark calendar + time picker dialog styled after the Listodo UI Kit.
/// Returns the selected [DateTime] (with hour & minute) when the user taps Save.
class ListodoCalendarDialog extends StatefulWidget {
  const ListodoCalendarDialog({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<ListodoCalendarDialog> createState() => _ListodoCalendarDialogState();
}

class _ListodoCalendarDialogState extends State<ListodoCalendarDialog> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;

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

  static const _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(base.year, base.month, base.day);
    _displayedMonth = DateTime(base.year, base.month);
    _selectedHour = base.hour;
    _selectedMinute = base.minute;
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  void _selectPreset(DateTime target) {
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _displayedMonth = DateTime(target.year, target.month);
    });
  }

  void _adjustHour(int delta) {
    setState(() {
      _selectedHour = (_selectedHour + delta) % 24;
      if (_selectedHour < 0) _selectedHour += 24;
    });
  }

  void _adjustMinute(int delta) {
    setState(() {
      _selectedMinute = (_selectedMinute + delta) % 60;
      if (_selectedMinute < 0) _selectedMinute += 60;
    });
  }

  DateTime _buildResult() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday; // 1 = Monday .. 7 = Sunday
    final leadingEmpty = firstWeekday - 1;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick preset chips
              Row(
                children: [
                  Expanded(
                    child: _PresetChip(
                      label: 'Сегодня',
                      isSelected: DateUtils.isSameDay(_selectedDate, today),
                      onTap: () => _selectPreset(today),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PresetChip(
                      label: 'Завтра',
                      isSelected: DateUtils.isSameDay(_selectedDate, tomorrow),
                      onTap: () => _selectPreset(tomorrow),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PresetChip(
                      label: '+7 дней',
                      isSelected: DateUtils.isSameDay(_selectedDate, nextWeek),
                      onTap: () => _selectPreset(nextWeek),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Month navigation header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.white,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _monthNames[_displayedMonth.month - 1],
                        style: const TextStyle(
                          color: AppColors.maintext,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_displayedMonth.year}',
                        style: const TextStyle(
                          color: AppColors.labeltext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weekday labels
              Row(
                children: _weekDays.map((day) {
                  final isWeekend = day == 'Сб' || day == 'Вс';
                  return Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isWeekend
                            ? const Color(0xFFFF6B6B)
                            : AppColors.labeltext,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar days grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingEmpty + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) {
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - leadingEmpty + 1;
                  final cellDate = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    dayNumber,
                  );
                  final isSelected = DateUtils.isSameDay(
                    cellDate,
                    _selectedDate,
                  );
                  final isToday = DateUtils.isSameDay(cellDate, today);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = cellDate),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.active
                            : AppColors.bgmain.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.accentYellow,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : (isToday
                                    ? AppColors.accentYellow
                                    : AppColors.maintext),
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),

              // Time Picker (Hours : Minutes)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: AppColors.accentYellow,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Время',
                        style: TextStyle(
                          color: AppColors.maintext,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimeSpinBox(
                        value: _selectedHour.toString().padLeft(2, '0'),
                        onIncrement: () => _adjustHour(1),
                        onDecrement: () => _adjustHour(-1),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ':',
                          style: TextStyle(
                            color: AppColors.maintext,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _TimeSpinBox(
                        value: _selectedMinute.toString().padLeft(2, '0'),
                        onIncrement: () => _adjustMinute(5),
                        onDecrement: () => _adjustMinute(-5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.labeltext,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _buildResult()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.active,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Выбрать',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentYellow : AppColors.bgmain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentYellow : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.labeltext,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TimeSpinBox extends StatelessWidget {
  const _TimeSpinBox({
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.remove, size: 14, color: AppColors.labeltext),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.maintext,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.add, size: 14, color: AppColors.accentYellow),
            ),
          ),
        ],
      ),
    );
  }
}
