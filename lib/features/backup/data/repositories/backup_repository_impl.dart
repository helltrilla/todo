import 'dart:isolate';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/data/datasources/backup_native_data_source.dart';
import 'package:todo/features/backup/data/datasources/task_data_serializer.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/backup/domain/repositories/i_backup_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Clean Architecture repository implementation for backup and export.
/// Executes heavy serialization and deserialization in background Isolates.
class BackupRepositoryImpl implements IBackupRepository {
  const BackupRepositoryImpl({
    BackupNativeDataSource dataSource = const BackupNativeDataSource(),
  }) : _dataSource = dataSource;

  final BackupNativeDataSource _dataSource;

  @override
  Future<Result<ExportResult>> exportTasks({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  }) async {
    try {
      final taskMaps = tasks.map((t) => t.toMap()).toList();

      final content = await Isolate.run(() {
        switch (format) {
          case ExportFormat.json:
            return TaskDataSerializer.toJsonString(taskMaps, categories);
          case ExportFormat.csv:
            return TaskDataSerializer.toCsvString(taskMaps);
          case ExportFormat.markdown:
            return TaskDataSerializer.toMarkdownString(taskMaps);
        }
      });

      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'todoapp_export_$stamp${format.extension}';

      return Success(
        ExportResult(
          fileName: fileName,
          content: content,
          format: format,
          taskCount: tasks.length,
          byteLength: content.length,
        ),
      );
    } catch (e) {
      return Error(ServerFailure('Ошибка сериализации бэкапа: $e'));
    }
  }

  @override
  Future<Result<List<Task>>> importTasksFromJson(String jsonContent) async {
    try {
      final tasks = await Isolate.run(() {
        return TaskDataSerializer.fromJsonString(jsonContent);
      });
      return Success(tasks);
    } on FormatException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось импортировать файл: $e'));
    }
  }

  @override
  Future<Result<void>> shareExport(ExportResult exportResult) async {
    try {
      await _dataSource.shareFile(
        fileName: exportResult.fileName,
        content: exportResult.content,
        mimeType: exportResult.format.mimeType,
      );
      return const Success(null);
    } on BackupNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось поделиться файлом: $e'));
    }
  }
}
