import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/productivity/domain/entities/category_stat.dart';
import 'package:todo/features/productivity/domain/entities/heatmap_day.dart';
import 'package:todo/features/productivity/domain/entities/priority_stat.dart';
import 'package:todo/features/productivity/domain/entities/productivity_dashboard.dart';
import 'package:todo/features/productivity/domain/repositories/i_productivity_repository.dart';
import 'package:todo/features/tasks/domain/models/priority_level.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// High-performance implementation of [IProductivityRepository].
/// Executes single-pass O(N) bucketing and metrics calculation.
class ProductivityRepositoryImpl implements IProductivityRepository {
  const ProductivityRepositoryImpl();

  @override
  Future<Result<ProductivityDashboard>> getDashboard({
    required List<Task> tasks,
    int daysRange = 120,
    DateTime? referenceDate,
  }) async {
    try {
      final now = referenceDate ?? DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final totalTasks = tasks.length;
      if (totalTasks == 0) {
        return const Success(ProductivityDashboard.empty);
      }

      var completedCount = 0;
      var urgentPending = 0;
      var totalPomodoroSessions = 0;
      var totalFocusMinutes = 0;
      var todayFocusMinutes = 0;
      var weekFocusMinutes = 0;

      final completedCalendarDays = <DateTime>{};
      final dailyCompletedCounts = <DateTime, int>{};
      final dailyFocusMinutes = <DateTime, int>{};

      final categoryTaskCounts = <String, int>{};
      final categoryCompletedCounts = <String, int>{};
      final categoryFocusMap = <String, int>{};

      final priorityTaskCounts = <int, int>{};
      final priorityCompletedCounts = <int, int>{};

      final sevenDaysAgo = todayMidnight.subtract(const Duration(days: 7));

      // Single pass O(N) aggregation
      for (final task in tasks) {
        totalPomodoroSessions += task.pomodoroCount;
        totalFocusMinutes += task.focusMinutes;

        // Category stats
        final cat = task.category.trim().isEmpty
            ? 'Без категории'
            : task.category.trim();
        categoryTaskCounts[cat] = (categoryTaskCounts[cat] ?? 0) + 1;
        categoryFocusMap[cat] =
            (categoryFocusMap[cat] ?? 0) + task.focusMinutes;

        // Priority stats
        final pIndex = task.priority.index;
        priorityTaskCounts[pIndex] = (priorityTaskCounts[pIndex] ?? 0) + 1;

        if (task.isCompleted) {
          completedCount++;
          categoryCompletedCounts[cat] =
              (categoryCompletedCounts[cat] ?? 0) + 1;
          priorityCompletedCounts[pIndex] =
              (priorityCompletedCounts[pIndex] ?? 0) + 1;

          final completedDate =
              task.completedAt ?? task.dueDate ?? task.createdAt;
          final dayKey = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );
          completedCalendarDays.add(dayKey);
          dailyCompletedCounts[dayKey] =
              (dailyCompletedCounts[dayKey] ?? 0) + 1;
          dailyFocusMinutes[dayKey] =
              (dailyFocusMinutes[dayKey] ?? 0) + task.focusMinutes;

          if (dayKey == todayMidnight) {
            todayFocusMinutes += task.focusMinutes;
          }
          if (!dayKey.isBefore(sevenDaysAgo)) {
            weekFocusMinutes += task.focusMinutes;
          }
        } else {
          if (task.priority == PriorityLevel.p1) {
            urgentPending++;
          }
        }
      }

      final pendingCount = totalTasks - completedCount;
      final completionRate = totalTasks > 0
          ? (completedCount / totalTasks)
          : 0.0;

      // Calculate Current & Best Streak
      final currentStreak = _calculateCurrentStreak(
        completedCalendarDays,
        todayMidnight,
      );
      final bestStreak = _calculateBestStreak(completedCalendarDays);

      // Generate Heatmap Days Sequence
      final heatmapDays = <HeatmapDay>[];
      for (var i = daysRange - 1; i >= 0; i--) {
        final d = todayMidnight.subtract(Duration(days: i));
        final count = dailyCompletedCounts[d] ?? 0;
        final fMin = dailyFocusMinutes[d] ?? 0;
        final level = _determineLevel(count);

        heatmapDays.add(
          HeatmapDay(
            date: d,
            completedCount: count,
            focusMinutes: fMin,
            level: level,
          ),
        );
      }

      // Generate Category Distribution
      final categoryStats = <CategoryStat>[];
      for (final entry in categoryTaskCounts.entries) {
        final cat = entry.key;
        final tCount = entry.value;
        final cCount = categoryCompletedCounts[cat] ?? 0;
        final fMin = categoryFocusMap[cat] ?? 0;
        final pct = totalTasks > 0 ? (tCount / totalTasks) * 100.0 : 0.0;

        categoryStats.add(
          CategoryStat(
            categoryName: cat,
            taskCount: tCount,
            completedCount: cCount,
            percentage: pct,
            focusMinutes: fMin,
          ),
        );
      }
      categoryStats.sort((a, b) => b.taskCount.compareTo(a.taskCount));

      // Generate Priority Distribution
      final priorityLabels = {
        0: 'Срочно (P1)',
        1: 'Высокий (P2)',
        2: 'Средний (P3)',
        3: 'Низкий (P4)',
      };
      final priorityStats = <PriorityStat>[];
      for (var p = 0; p < 4; p++) {
        final tCount = priorityTaskCounts[p] ?? 0;
        final cCount = priorityCompletedCounts[p] ?? 0;
        final pct = totalTasks > 0 ? (tCount / totalTasks) * 100.0 : 0.0;

        priorityStats.add(
          PriorityStat(
            priorityIndex: p,
            label: priorityLabels[p] ?? 'P$p',
            taskCount: tCount,
            completedCount: cCount,
            percentage: pct,
          ),
        );
      }

      final completedToday = dailyCompletedCounts[todayMidnight] ?? 0;

      return Success(
        ProductivityDashboard(
          totalTasks: totalTasks,
          completedTasks: completedCount,
          pendingTasks: pendingCount,
          urgentPending: urgentPending,
          completionRate: completionRate,
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          completedToday: completedToday,
          totalPomodoroSessions: totalPomodoroSessions,
          totalFocusMinutes: totalFocusMinutes,
          todayFocusMinutes: todayFocusMinutes,
          weekFocusMinutes: weekFocusMinutes,
          heatmapDays: heatmapDays,
          categoryStats: categoryStats,
          priorityStats: priorityStats,
        ),
      );
    } catch (e) {
      return Error(ServerFailure('Ошибка вычисления статистики: $e'));
    }
  }

  int _determineLevel(int count) {
    if (count <= 0) return 0;
    if (count <= 2) return 1;
    if (count <= 4) return 2;
    if (count <= 7) return 3;
    return 4;
  }

  int _calculateCurrentStreak(Set<DateTime> activeDays, DateTime today) {
    if (activeDays.isEmpty) return 0;
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime cursor;
    if (activeDays.contains(today)) {
      cursor = today;
    } else if (activeDays.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calculateBestStreak(Set<DateTime> activeDays) {
    final sorted = activeDays.toList()..sort();
    if (sorted.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final expected = prev.add(const Duration(days: 1));
      if (sorted[i] == expected) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }
}
