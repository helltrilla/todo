import 'package:todo/features/productivity/domain/entities/category_stat.dart';
import 'package:todo/features/productivity/domain/entities/heatmap_day.dart';
import 'package:todo/features/productivity/domain/entities/priority_stat.dart';

/// Pure Dart aggregate entity holding complete productivity analytics for the user.
class ProductivityDashboard {
  const ProductivityDashboard({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.urgentPending,
    required this.completionRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.completedToday,
    required this.totalPomodoroSessions,
    required this.totalFocusMinutes,
    required this.todayFocusMinutes,
    required this.weekFocusMinutes,
    required this.heatmapDays,
    required this.categoryStats,
    required this.priorityStats,
  });

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int urgentPending;
  final double completionRate; // 0.0 .. 1.0
  final int currentStreak;
  final int bestStreak;
  final int completedToday;

  final int totalPomodoroSessions;
  final int totalFocusMinutes;
  final int todayFocusMinutes;
  final int weekFocusMinutes;

  final List<HeatmapDay> heatmapDays;
  final List<CategoryStat> categoryStats;
  final List<PriorityStat> priorityStats;

  static const ProductivityDashboard empty = ProductivityDashboard(
    totalTasks: 0,
    completedTasks: 0,
    pendingTasks: 0,
    urgentPending: 0,
    completionRate: 0.0,
    currentStreak: 0,
    bestStreak: 0,
    completedToday: 0,
    totalPomodoroSessions: 0,
    totalFocusMinutes: 0,
    todayFocusMinutes: 0,
    weekFocusMinutes: 0,
    heatmapDays: [],
    categoryStats: [],
    priorityStats: [],
  );
}
