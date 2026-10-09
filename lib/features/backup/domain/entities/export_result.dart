import 'package:todo/features/backup/domain/entities/export_format.dart';

/// Pure Dart domain entity representing an exported backup artifact.
class ExportResult {
  const ExportResult({
    required this.fileName,
    required this.content,
    required this.format,
    required this.taskCount,
    required this.byteLength,
  });

  final String fileName;
  final String content;
  final ExportFormat format;
  final int taskCount;
  final int byteLength;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResult &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          content == other.content &&
          format == other.format &&
          taskCount == other.taskCount;

  @override
  int get hashCode => Object.hash(fileName, content, format, taskCount);
}
