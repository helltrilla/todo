import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/productivity/data/repositories/productivity_repository_impl.dart';
import 'package:todo/features/productivity/domain/entities/heatmap_day.dart';
import 'package:todo/features/productivity/domain/entities/productivity_dashboard.dart';
import 'package:todo/features/productivity/domain/usecases/calculate_productivity_dashboard_use_case.dart';
import 'package:todo/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

void main() {
  group('Feature 2: Productivity Dashboard & Heatmap Analytics Tests', () {
    late ProductivityRepositoryImpl repo;
    late CalculateProductivityDashboardUseCase useCase;

    setUp(() {
      repo = const ProductivityRepositoryImpl();
      useCase = CalculateProductivityDashboardUseCase(repo);
    });

    test('returns empty dashboard when task list is empty', () async {
      final result = await useCase(tasks: []);

      expect(result, isA<Success<ProductivityDashboard>>());
      final data = (result as Success<ProductivityDashboard>).data;
      expect(data.totalTasks, 0);
      expect(data.completedTasks, 0);
      expect(data.heatmapDays, isEmpty);
    });

    test(
      'aggregates completion rate, categories, priorities and heatmap correctly',
      () async {
        final now = DateTime(2026, 10, 9, 12, 0);

        final tasks = [
          Task(
            id: 1,
            name: 'Task 1',
            value: '',
            createdAt: now,
            category: 'Работа',
            priorityIndex: 0, // P1 Urgent
            isCompleted: true,
            completedAt: DateTime(2026, 10, 9, 10, 0),
            focusMinutes: 25,
            pomodoroCount: 1,
          ),
          Task(
            id: 2,
            name: 'Task 2',
            value: '',
            createdAt: now,
            category: 'Работа',
            priorityIndex: 1, // P2 High
            isCompleted: true,
            completedAt: DateTime(2026, 10, 8, 15, 0),
            focusMinutes: 50,
            pomodoroCount: 2,
          ),
          Task(
            id: 3,
            name: 'Task 3',
            value: '',
            createdAt: now,
            category: 'Учеба',
            priorityIndex: 2, // P3 Medium
            isCompleted: false,
            focusMinutes: 0,
            pomodoroCount: 0,
          ),
          Task(
            id: 4,
            name: 'Task 4',
            value: '',
            createdAt: now,
            category: 'Учеба',
            priorityIndex: 0, // P1 Urgent
            isCompleted: false,
            focusMinutes: 0,
            pomodoroCount: 0,
          ),
        ];

        final result = await useCase(
          tasks: tasks,
          daysRange: 30,
          referenceDate: now,
        );

        expect(result, isA<Success<ProductivityDashboard>>());
        final d = (result as Success<ProductivityDashboard>).data;

        expect(d.totalTasks, 4);
        expect(d.completedTasks, 2);
        expect(d.pendingTasks, 2);
        expect(d.urgentPending, 1); // Task 4 is P1 urgent and incomplete
        expect(d.completionRate, 0.5);

        // Pomodoro stats
        expect(d.totalPomodoroSessions, 3);
        expect(d.totalFocusMinutes, 75);
        expect(d.todayFocusMinutes, 25);

        // Streaks: today (Oct 9) and yesterday (Oct 8) completed -> streak = 2
        expect(d.currentStreak, 2);
        expect(d.bestStreak, 2);

        // Heatmap
        expect(d.heatmapDays.length, 30);
        final todayHeatmap = d.heatmapDays.firstWhere(
          (day) =>
              day.date.year == 2026 &&
              day.date.month == 10 &&
              day.date.day == 9,
        );
        expect(todayHeatmap.completedCount, 1);
        expect(todayHeatmap.focusMinutes, 25);
        expect(todayHeatmap.level, 1);

        // Category breakdown
        expect(d.categoryStats.length, 2);
        final workCat = d.categoryStats.firstWhere(
          (c) => c.categoryName == 'Работа',
        );
        expect(workCat.taskCount, 2);
        expect(workCat.completedCount, 2);
        expect(workCat.percentage, 50.0);
      },
    );

    test(
      'high-performance stress test: aggregates 2,000 tasks in < 50ms without lag',
      () async {
        final now = DateTime(2026, 10, 9);
        final tasks = List.generate(2000, (i) {
          final isDone = i % 2 == 0;
          final dayOffset = i % 100;
          return Task(
            id: i,
            name: 'Task #$i',
            value: '',
            createdAt: now,
            category: 'Категория ${i % 5}',
            priorityIndex: i % 4,
            isCompleted: isDone,
            completedAt: isDone
                ? now.subtract(Duration(days: dayOffset))
                : null,
            focusMinutes: isDone ? 25 : 0,
            pomodoroCount: isDone ? 1 : 0,
          );
        });

        final stopwatch = Stopwatch()..start();
        final result = await useCase(
          tasks: tasks,
          daysRange: 120,
          referenceDate: now,
        );
        stopwatch.stop();

        expect(result, isA<Success<ProductivityDashboard>>());
        final data = (result as Success<ProductivityDashboard>).data;
        expect(data.totalTasks, 2000);
        expect(data.completedTasks, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      },
    );

    test(
      'ProductivityController updates dashboard and manages day selection',
      () async {
        final controller = ProductivityController(
          calculateDashboardUseCase: useCase,
        );

        expect(controller.dashboard.totalTasks, 0);
        expect(controller.selectedDay, isNull);

        final tasks = [
          Task(
            id: 10,
            name: 'Test Task',
            value: '',
            createdAt: DateTime.now(),
            priorityIndex: 1,
            isCompleted: true,
            completedAt: DateTime.now(),
          ),
        ];

        await controller.computeDashboard(tasks);
        expect(controller.dashboard.totalTasks, 1);
        expect(controller.dashboard.completedTasks, 1);

        final sampleDay = HeatmapDay(
          date: DateTime.now(),
          completedCount: 2,
          focusMinutes: 50,
          level: 1,
        );

        controller.selectDay(sampleDay);
        expect(controller.selectedDay, sampleDay);

        // Toggling same day deselects it
        controller.selectDay(sampleDay);
        expect(controller.selectedDay, isNull);
      },
    );
  });
}
