import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/haptics/app_haptics.dart';
import 'package:todo/features/productivity/domain/entities/heatmap_day.dart';

/// GitHub-style contribution activity heatmap widget.
class GithubHeatmapCard extends StatelessWidget {
  const GithubHeatmapCard({
    super.key,
    required this.heatmapDays,
    required this.selectedDay,
    required this.onDaySelected,
    required this.currentStreak,
    required this.bestStreak,
  });

  final List<HeatmapDay> heatmapDays;
  final HeatmapDay? selectedDay;
  final ValueChanged<HeatmapDay> onDaySelected;
  final int currentStreak;
  final int bestStreak;

  static const List<Color> _darkLevelColors = [
    Color(0xFF161B22), // 0: None
    Color(0xFF0E4429), // 1: 1-2
    Color(0xFF006D32), // 2: 3-4
    Color(0xFF26A641), // 3: 5-7
    Color(0xFF39D353), // 4: 8+
  ];

  static const List<Color> _lightLevelColors = [
    Color(0xFFEBEDF0), // 0: None
    Color(0xFF9BE9A8), // 1: 1-2
    Color(0xFF40C463), // 2: 3-4
    Color(0xFF30A14E), // 3: 5-7
    Color(0xFF216E39), // 4: 8+
  ];

  static const List<String> _weekdayLabels = [
    'Пн',
    '',
    'Ср',
    '',
    'Пт',
    '',
    'Вс',
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final levelColors = isLight ? _lightLevelColors : _darkLevelColors;

    // Group days into week columns (each column has up to 7 days, Mon..Sun)
    final weeks = _buildWeeksMatrix(heatmapDays);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A641).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF39D353),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тепловая карта активности',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GitHub-style матрица за 120 дней',
                      style: TextStyle(
                        color: AppColors.labeltext,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF8A00),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak дн.',
                      style: const TextStyle(
                        color: Color(0xFFFF8A00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable Heatmap Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Show most recent days on the right
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels column
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 2),
                  child: Column(
                    children: List.generate(7, (i) {
                      return SizedBox(
                        height: 16,
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Matrix Columns
                ...weeks.map((week) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      children: List.generate(7, (dayIndex) {
                        final day = week[dayIndex];
                        if (day == null) {
                          return const SizedBox(width: 14, height: 16);
                        }
                        final isSelected = selectedDay == day;
                        final color = levelColors[day.level.clamp(0, 4)];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: GestureDetector(
                            onTap: () {
                              AppHaptics.selection();
                              onDaySelected(day);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border.withValues(alpha: 0.4),
                                  width: isSelected ? 1.5 : 0.6,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Footer with Legend and Selected Day Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Legend
              Row(
                children: [
                  Text(
                    'Меньше',
                    style: TextStyle(color: AppColors.labeltext, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (idx) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: levelColors[idx],
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    'Больше',
                    style: TextStyle(color: AppColors.labeltext, fontSize: 10),
                  ),
                ],
              ),
              Text(
                'Рекорд: $bestStreak дн.',
                style: TextStyle(
                  color: AppColors.labeltext,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (selectedDay != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgmain,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF26A641).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Color(0xFF39D353),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatDate(selectedDay!.date)}: выполнено ${selectedDay!.completedCount} задач'
                      '${selectedDay!.focusMinutes > 0 ? ' • ${selectedDay!.focusMinutes} мин фокуса' : ''}',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  String _formatDate(DateTime d) {
    const months = [
      '',
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  List<List<HeatmapDay?>> _buildWeeksMatrix(List<HeatmapDay> days) {
    if (days.isEmpty) return [];

    final result = <List<HeatmapDay?>>[];
    var currentWeek = List<HeatmapDay?>.filled(7, null);

    for (final day in days) {
      final weekdayIndex = day.date.weekday - 1; // 0 = Mon, 6 = Sun
      currentWeek[weekdayIndex] = day;

      if (weekdayIndex == 6) {
        result.add(currentWeek);
        currentWeek = List<HeatmapDay?>.filled(7, null);
      }
    }

    if (currentWeek.any((d) => d != null)) {
      result.add(currentWeek);
    }

    return result;
  }
}
