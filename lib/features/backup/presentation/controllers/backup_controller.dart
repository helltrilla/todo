import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/backup/domain/usecases/export_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/import_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/share_backup_use_case.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Presentation state controller for exporting, importing, and sharing tasks.
/// Communicates STRICTLY with Use Cases without touching repositories directly.
class BackupController extends ChangeNotifier {
  BackupController({
    required ExportTasksUseCase exportUseCase,
    required ImportTasksUseCase importUseCase,
    required ShareBackupUseCase shareUseCase,
  }) : _exportUseCase = exportUseCase,
       _importUseCase = importUseCase,
       _shareUseCase = shareUseCase;

  final ExportTasksUseCase _exportUseCase;
  final ImportTasksUseCase _importUseCase;
  final ShareBackupUseCase _shareUseCase;

  bool _isProcessing = false;
  ExportResult? _lastExport;
  String? _errorMessage;
  String? _successMessage;

  bool get isProcessing => _isProcessing;
  ExportResult? get lastExport => _lastExport;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<ExportResult?> exportTasks({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _exportUseCase(
      tasks: tasks,
      format: format,
      categories: categories,
    );

    switch (result) {
      case Success(:final data):
        _lastExport = data;
        _isProcessing = false;
        _successMessage = 'Экспорт ${data.fileName} успешно создан';
        notifyListeners();
        return data;
      case Error(:final failure):
        _isProcessing = false;
        _errorMessage = failure.message;
        notifyListeners();
        return null;
    }
  }

  Future<bool> exportAndShare({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  }) async {
    final exportResult = await exportTasks(
      tasks: tasks,
      format: format,
      categories: categories,
    );

    if (exportResult == null) return false;

    _isProcessing = true;
    notifyListeners();

    final shareResult = await _shareUseCase(exportResult);
    _isProcessing = false;

    switch (shareResult) {
      case Success():
        _successMessage = 'Файл ${exportResult.fileName} отправлен';
        notifyListeners();
        return true;
      case Error(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  Future<List<Task>?> importTasks({required String jsonContent}) async {
    _isProcessing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _importUseCase(jsonContent);
    _isProcessing = false;

    switch (result) {
      case Success(:final data):
        _successMessage = 'Успешно импортировано ${data.length} задач';
        notifyListeners();
        return data;
      case Error(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return null;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
