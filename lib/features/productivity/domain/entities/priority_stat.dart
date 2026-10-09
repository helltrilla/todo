/// Pure Dart domain entity for priority distribution metrics.
class PriorityStat {
  const PriorityStat({
    required this.priorityIndex,
    required this.label,
    required this.taskCount,
    required this.completedCount,
    required this.percentage,
  });

  /// -1 = default/none, 0 = P1 Urgent, 1 = P2 High, 2 = P3 Medium, 3 = P4 Low
  final int priorityIndex;
  final String label;
  final int taskCount;
  final int completedCount;
  final double percentage; // 0.0 .. 100.0

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityStat &&
          runtimeType == other.runtimeType &&
          priorityIndex == other.priorityIndex &&
          label == other.label &&
          taskCount == other.taskCount &&
          completedCount == other.completedCount &&
          percentage == other.percentage;

  @override
  int get hashCode =>
      Object.hash(priorityIndex, label, taskCount, completedCount, percentage);
}
