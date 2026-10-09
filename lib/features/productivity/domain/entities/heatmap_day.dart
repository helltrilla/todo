/// Pure Dart domain entity representing a single day in the GitHub-style heatmap.
/// Zero Flutter framework dependencies, pure Dart.
class HeatmapDay {
  const HeatmapDay({
    required this.date,
    required this.completedCount,
    required this.focusMinutes,
    required this.level,
  });

  /// Normalized calendar date (midnight).
  final DateTime date;

  /// Count of tasks completed on this day.
  final int completedCount;

  /// Total Pomodoro focus minutes logged on this day.
  final int focusMinutes;

  /// Visual intensity level: 0 (none), 1 (1-2), 2 (3-4), 3 (5-7), 4 (8+).
  final int level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDay &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          completedCount == other.completedCount &&
          focusMinutes == other.focusMinutes &&
          level == other.level;

  @override
  int get hashCode => Object.hash(
    date.year,
    date.month,
    date.day,
    completedCount,
    focusMinutes,
    level,
  );
}
