import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/features/productivity/domain/entities/category_stat.dart';
import 'package:todo/features/productivity/domain/entities/priority_stat.dart';

/// Donut chart card illustrating Category and Priority breakdowns.
class CategoryDonutChartCard extends StatelessWidget {
  const CategoryDonutChartCard({
    super.key,
    required this.categoryStats,
    required this.priorityStats,
    required this.totalTasks,
    required this.completionRate,
  });

  final List<CategoryStat> categoryStats;
  final List<PriorityStat> priorityStats;
  final int totalTasks;
  final double completionRate;

  static const List<Color> _palette = [
    Color(0xFF8687E7), // Indigo
    Color(0xFF3ECF8E), // Emerald
    Color(0xFFFF8A00), // Amber/Orange
    Color(0xFFFF4D4F), // Red
    Color(0xFF00B4D8), // Cyan
    Color(0xFFE040FB), // Magenta
    Color(0xFFFFD166), // Yellow
  ];

  @override
  Widget build(BuildContext context) {
    if (totalTasks == 0) {
      return const SizedBox.shrink();
    }

    final topCategories = categoryStats.take(5).toList();

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
                  color: AppColors.active.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppColors.active,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Распределение по категориям',
                  style: TextStyle(
                    color: AppColors.maintext,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Donut Chart + Legend Row
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    stats: topCategories,
                    colors: _palette,
                    totalTasks: totalTasks,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(completionRate * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.maintext,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'готово',
                          style: TextStyle(
                            color: AppColors.labeltext,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Category Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(topCategories.length, (idx) {
                    final item = topCategories[idx];
                    final color = _palette[idx % _palette.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.maintext,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${item.taskCount} (${item.percentage.round()}%)',
                            style: const TextStyle(
                              color: AppColors.labeltext,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          // Priority Bar Distribution
          const Text(
            'Приоритеты задач',
            style: TextStyle(
              color: AppColors.labeltext,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: priorityStats.map((p) {
              final color = _priorityColor(p.priorityIndex);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        p.label.split(' ').first,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.taskCount}',
                        style: const TextStyle(
                          color: AppColors.maintext,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(int pIndex) {
    switch (pIndex) {
      case 0:
        return const Color(0xFFFF4D4F); // P1
      case 1:
        return const Color(0xFFFF8A00); // P2
      case 2:
        return const Color(0xFF00B4D8); // P3
      default:
        return AppColors.labeltext; // P4
    }
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.stats,
    required this.colors,
    required this.totalTasks,
  });

  final List<CategoryStat> stats;
  final List<Color> colors;
  final int totalTasks;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalTasks == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    var startAngle = -math.pi / 2;

    for (var i = 0; i < stats.length; i++) {
      final sweepAngle = (stats[i].taskCount / totalTasks) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (sweepAngle > 0.05) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle - 0.04, // slight gap between arcs
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalTasks != totalTasks || oldDelegate.stats != stats;
  }
}
