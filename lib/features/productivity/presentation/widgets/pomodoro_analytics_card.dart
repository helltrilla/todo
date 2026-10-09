import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';

/// Pomodoro & Deep Work focus time analytics card.
class PomodoroAnalyticsCard extends StatelessWidget {
  const PomodoroAnalyticsCard({
    super.key,
    required this.totalSessions,
    required this.totalFocusMinutes,
    required this.todayFocusMinutes,
    required this.weekFocusMinutes,
  });

  final int totalSessions;
  final int totalFocusMinutes;
  final int todayFocusMinutes;
  final int weekFocusMinutes;

  @override
  Widget build(BuildContext context) {
    final totalHours = (totalFocusMinutes / 60).toStringAsFixed(1);
    final weekHours = (weekFocusMinutes / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🍅', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Инфографика Pomodoro',
                      style: TextStyle(
                        color: AppColors.maintext,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Статистика концентрации и таймера',
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
                  color: const Color(0xFFFF4D4F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalSessions сессий',
                  style: const TextStyle(
                    color: Color(0xFFFF4D4F),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PomodoroStatTile(
                  title: 'Всего времени',
                  value: '$totalHours ч',
                  subtitle: '$totalFocusMinutes мин',
                  accentColor: const Color(0xFFFF4D4F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PomodoroStatTile(
                  title: 'За 7 дней',
                  value: '$weekHours ч',
                  subtitle: '$weekFocusMinutes мин',
                  accentColor: AppColors.accentYellow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PomodoroStatTile(
                  title: 'Сегодня',
                  value: '$todayFocusMinutes м',
                  subtitle: todayFocusMinutes > 0 ? 'Фокус активен' : 'Отдых',
                  accentColor: const Color(0xFF3ECF8E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PomodoroStatTile extends StatelessWidget {
  const _PomodoroStatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgmain,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.labeltext,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.labeltext, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
