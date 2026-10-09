/// Pure Dart domain entity representing a lightweight task entry for widgets.
/// Contains ZERO Flutter imports and ZERO serialization methods.
class WidgetTaskItem {
  const WidgetTaskItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priorityIndex,
    required this.category,
    this.dueDateLabel,
  });

  final int id;
  final String title;
  final bool isCompleted;
  final int priorityIndex;
  final String category;
  final String? dueDateLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetTaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          priorityIndex == other.priorityIndex &&
          category == other.category &&
          dueDateLabel == other.dueDateLabel;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    isCompleted,
    priorityIndex,
    category,
    dueDateLabel,
  );
}
