import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';

/// Custom dark calendar + iOS-style dual wheel time picker dialog + reminder picker.
/// Returns the selected [DateTime] (with hour & minute) when the user taps Save.
class ListodoCalendarDialog extends StatefulWidget {
  const ListodoCalendarDialog({
    super.key,
    this.initialDate,
    this.initialReminderMinutes = 15,
    this.onReminderChanged,
  });

  final DateTime? initialDate;
  final int? initialReminderMinutes;
  final ValueChanged<int?>? onReminderChanged;

  @override
  State<ListodoCalendarDialog> createState() => _ListodoCalendarDialogState();
}

class _ListodoCalendarDialogState extends State<ListodoCalendarDialog> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;
  int? _selectedReminderMinutes;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const List<(int?, String)> _reminderOptions = <(int?, String)>[
    (null, 'Только в момент'),
    (5, 'За 5 мин'),
    (15, 'За 15 мин'),
    (30, 'За 30 мин'),
    (60, 'За 1 час'),
    (1440, 'За 1 день'),
  ];

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
    _selectedReminderMinutes = widget.initialReminderMinutes;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    AppHaptics.selection();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  void _selectPreset(DateTime target) {
    AppHaptics.selection();
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _displayedMonth = DateTime(target.year, target.month);
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
    ).weekday;
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
              const SizedBox(height: 12),

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
              const SizedBox(height: 6),

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
              const SizedBox(height: 6),

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
                    onTap: () {
                      AppHaptics.selection();
                      setState(() => _selectedDate = cellDate);
                    },
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

              // iOS-style Dual Wheel Time Picker (Hours & Minutes)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.accentYellow,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Время',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.bgmain,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 30,
                        looping: true,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x228875FF),
                            ),
                        onSelectedItemChanged: (index) {
                          AppHaptics.selection();
                          setState(() => _selectedHour = index);
                        },
                        children: List.generate(24, (hour) {
                          final isCurrent = hour == _selectedHour;
                          return Center(
                            child: Text(
                              '${hour.toString().padLeft(2, '0')} ч',
                              style: TextStyle(
                                color: isCurrent
                                    ? AppColors.accentYellow
                                    : AppColors.maintext,
                                fontSize: isCurrent ? 16 : 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 30,
                        looping: true,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(
                              background: Color(0x228875FF),
                            ),
                        onSelectedItemChanged: (index) {
                          AppHaptics.selection();
                          setState(() => _selectedMinute = index);
                        },
                        children: List.generate(60, (minute) {
                          final isCurrent = minute == _selectedMinute;
                          return Center(
                            child: Text(
                              '${minute.toString().padLeft(2, '0')} мин',
                              style: TextStyle(
                                color: isCurrent
                                    ? AppColors.accentYellow
                                    : AppColors.maintext,
                                fontSize: isCurrent ? 16 : 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Push Notification Reminder Section
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.accentYellow,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Уведомление до задачи',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '⚡ В сам момент задачи уведомление придёт автоматически',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.labeltext, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _reminderOptions.map((option) {
                  final (minutes, label) = option;
                  final isSelected = _selectedReminderMinutes == minutes;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      setState(() => _selectedReminderMinutes = minutes);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.active
                            : AppColors.bgmain.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.active : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            minutes == null
                                ? Icons.alarm_on_rounded
                                : Icons.notifications_none_rounded,
                            size: 13,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.maintext,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

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
                      onPressed: () {
                        AppHaptics.medium();
                        widget.onReminderChanged?.call(
                          _selectedReminderMinutes,
                        );
                        Navigator.pop(context, _buildResult());
                      },
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
