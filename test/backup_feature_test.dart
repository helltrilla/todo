import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/data/datasources/task_data_serializer.dart';
import 'package:todo/features/backup/domain/entities/export_format.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/backup/domain/repositories/i_backup_repository.dart';
import 'package:todo/features/backup/domain/usecases/export_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/import_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/share_backup_use_case.dart';
import 'package:todo/features/backup/presentation/controllers/backup_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class _FakeBackupRepository implements IBackupRepository {
  List<Task>? importedTasks;
  ExportResult? sharedExport;
  bool shouldFail = false;

  @override
  Future<Result<ExportResult>> exportTasks({
    required List<Task> tasks,
    required ExportFormat format,
    List<String>? categories,
  }) async {
    if (shouldFail) {
      return const Error(ServerFailure('Export failed test error'));
    }
    final rawMaps = tasks.map((t) => t.toMap()).toList();
    final String content;
    switch (format) {
      case ExportFormat.json:
        content = TaskDataSerializer.toJsonString(rawMaps, categories);
      case ExportFormat.csv:
        content = TaskDataSerializer.toCsvString(rawMaps);
      case ExportFormat.markdown:
        content = TaskDataSerializer.toMarkdownString(rawMaps);
    }

    return Success(
      ExportResult(
        format: format,
        fileName: 'test_export.${format.extension}',
        content: content,
        taskCount: tasks.length,
        byteLength: utf8.encode(content).length,
      ),
    );
  }

  @override
  Future<Result<List<Task>>> importTasksFromJson(String jsonContent) async {
    if (shouldFail) {
      return const Error(ServerFailure('Import failed test error'));
    }
    try {
      final tasks = TaskDataSerializer.fromJsonString(jsonContent);
      importedTasks = tasks;
      return Success(tasks);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> shareExport(ExportResult exportResult) async {
    if (shouldFail) {
      return const Error(ServerFailure('Share failed test error'));
    }
    sharedExport = exportResult;
    return const Success(null);
  }
}

void main() {
  group('TaskDataSerializer tests', () {
    final now = DateTime(2026, 10, 9, 12, 0);
    final sampleTasks = [
      Task(
        id: 1,
        name: 'Buy Groceries, "Milk" & Eggs',
        value: 'Check expiration date on organic milk\nLine 2 notes',
        priorityIndex: 1, // High (P2)
        isCompleted: false,
        category: 'Personal',
        createdAt: now,
        dueDate: now.add(const Duration(days: 1)),
        pomodoroCount: 2,
        focusMinutes: 50,
      ),
      Task(
        id: 2,
        name: 'Finish Presentation',
        value: 'Prepare keynote slides',
        priorityIndex: 0, // Urgent (P1)
        isCompleted: true,
        category: 'Work',
        createdAt: now,
        pomodoroCount: 4,
        focusMinutes: 100,
      ),
    ];
    final sampleRawMaps = sampleTasks.map((t) => t.toMap()).toList();
    final sampleCategories = ['Personal', 'Work', 'Study'];

    test('Serializes to JSON with correct structure and metadata', () {
      final jsonString = TaskDataSerializer.toJsonString(
        sampleRawMaps,
        sampleCategories,
      );

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['version'], equals(AppConfig.appVersion));
      expect(decoded['appVersion'], equals(AppConfig.appVersion));
      expect(decoded['schemaVersion'], equals(1));
      expect(decoded['tasksCount'], equals(2));
      expect(decoded['categories'], equals(sampleCategories));

      final tasksList = decoded['tasks'] as List<dynamic>;
      expect(tasksList.length, equals(2));
      expect(tasksList[0]['id'], equals(1));
      expect(tasksList[0]['name'], equals('Buy Groceries, "Milk" & Eggs'));
      expect(tasksList[0]['isCompleted'], isFalse);
      expect(tasksList[1]['isCompleted'], isTrue);
    });

    test('Serializes to RFC 4180 compliant CSV', () {
      final csvString = TaskDataSerializer.toCsvString(sampleRawMaps);

      expect(csvString, contains('ID,Название,Описание,Категория,Приоритет'));
      expect(csvString, contains('1,"Buy Groceries, ""Milk"" & Eggs"'));
      expect(csvString, contains('В работе'));
      expect(csvString, contains('Personal'));
      expect(csvString, contains('2,Finish Presentation'));
      expect(csvString, contains('Выполнено'));
      expect(csvString, contains('Work'));
    });

    test('Serializes to Markdown with checklists and categories', () {
      final mdString = TaskDataSerializer.toMarkdownString(sampleRawMaps);

      expect(mdString, contains('# 📋 Экспорт задач TodoApp'));
      expect(mdString, contains('## 📁 Personal'));
      expect(mdString, contains('## 📁 Work'));

      // Pending task checklist
      expect(mdString, contains('- [ ] **Buy Groceries, "Milk" & Eggs**'));
      // Completed task checklist
      expect(mdString, contains('- [x] **Finish Presentation**'));
    });

    test('Deserializes JSON backup into Task domain entities', () {
      final jsonString = TaskDataSerializer.toJsonString(
        sampleRawMaps,
        sampleCategories,
      );

      final restored = TaskDataSerializer.fromJsonString(jsonString);
      expect(restored.length, equals(2));
      expect(restored[0].id, equals(1));
      expect(restored[0].name, equals('Buy Groceries, "Milk" & Eggs'));
      expect(restored[0].value, contains('Line 2 notes'));
      expect(restored[0].isCompleted, isFalse);
      expect(restored[1].id, equals(2));
      expect(restored[1].isCompleted, isTrue);
    });
  });

  group('Clean Architecture Backup Use Cases & Controller tests', () {
    late _FakeBackupRepository fakeRepo;
    late ExportTasksUseCase exportUseCase;
    late ImportTasksUseCase importUseCase;
    late ShareBackupUseCase shareUseCase;
    late BackupController controller;

    final testTasks = [
      Task(
        id: 1,
        name: 'Task 1',
        value: 'Desc 1',
        priorityIndex: 1,
        createdAt: DateTime.now(),
      ),
    ];
    final testCategories = ['Default'];

    setUp(() {
      fakeRepo = _FakeBackupRepository();
      exportUseCase = ExportTasksUseCase(fakeRepo);
      importUseCase = ImportTasksUseCase(fakeRepo);
      shareUseCase = ShareBackupUseCase(fakeRepo);
      controller = BackupController(
        exportUseCase: exportUseCase,
        importUseCase: importUseCase,
        shareUseCase: shareUseCase,
      );
    });

    test('ExportTasksUseCase calls repository and returns Success', () async {
      final result = await exportUseCase(
        tasks: testTasks,
        categories: testCategories,
        format: ExportFormat.json,
      );

      expect(result, isA<Success<ExportResult>>());
      final data = (result as Success<ExportResult>).data;
      expect(data.taskCount, equals(1));
      expect(data.format, equals(ExportFormat.json));
    });

    test('ExportTasksUseCase returns Failure when repository fails', () async {
      fakeRepo.shouldFail = true;
      final result = await exportUseCase(
        tasks: testTasks,
        categories: testCategories,
        format: ExportFormat.csv,
      );

      expect(result, isA<Error<ExportResult>>());
      final failure = (result as Error<ExportResult>).failure;
      expect(failure.message, contains('Export failed'));
    });

    test('ImportTasksUseCase successfully parses valid json', () async {
      final validJson = TaskDataSerializer.toJsonString(
        testTasks.map((t) => t.toMap()).toList(),
        testCategories,
      );
      final result = await importUseCase(validJson);
      expect(result, isA<Success<List<Task>>>());
      final parsed = (result as Success<List<Task>>).data;
      expect(parsed.length, equals(1));
      expect(parsed.first.name, equals('Task 1'));
    });

    test('ShareBackupUseCase invokes share on repository', () async {
      final exportResult = ExportResult(
        fileName: 'test.csv',
        content: 'col1,col2\nval1,val2',
        format: ExportFormat.csv,
        taskCount: 1,
        byteLength: 20,
      );

      final result = await shareUseCase(exportResult);

      expect(result, isA<Success<void>>());
      expect(fakeRepo.sharedExport, equals(exportResult));
    });

    test('BackupController manages export and share flow cleanly', () async {
      expect(controller.isProcessing, isFalse);
      expect(controller.lastExport, isNull);

      final exportRes = await controller.exportTasks(
        tasks: testTasks,
        categories: testCategories,
        format: ExportFormat.markdown,
      );

      expect(exportRes, isNotNull);
      expect(controller.lastExport, equals(exportRes));
      expect(controller.isProcessing, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.successMessage, contains('успешно создан'));

      // Now exportAndShare
      final shareSuccess = await controller.exportAndShare(
        tasks: testTasks,
        format: ExportFormat.markdown,
      );
      expect(shareSuccess, isTrue);
      expect(fakeRepo.sharedExport?.format, equals(ExportFormat.markdown));
    });

    test('BackupController records error on export failure', () async {
      fakeRepo.shouldFail = true;
      final exportRes = await controller.exportTasks(
        tasks: testTasks,
        categories: testCategories,
        format: ExportFormat.json,
      );

      expect(exportRes, isNull);
      expect(controller.isProcessing, isFalse);
      expect(controller.errorMessage, contains('Export failed'));
    });
  });
}
