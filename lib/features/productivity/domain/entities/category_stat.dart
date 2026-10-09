/// Pure Dart domain entity for category distribution metrics.
class CategoryStat {
  const CategoryStat({
    required this.categoryName,
    required this.taskCount,
    required this.completedCount,
    required this.percentage,
    required this.focusMinutes,
  });

  final String categoryName;
  final int taskCount;
  final int completedCount;
  final double percentage; // 0.0 .. 100.0
  final int focusMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryStat &&
          runtimeType == other.runtimeType &&
          categoryName == other.categoryName &&
          taskCount == other.taskCount &&
          completedCount == other.completedCount &&
          percentage == other.percentage &&
          focusMinutes == other.focusMinutes;

  @override
  int get hashCode => Object.hash(
    categoryName,
    taskCount,
    completedCount,
    percentage,
    focusMinutes,
  );
}
