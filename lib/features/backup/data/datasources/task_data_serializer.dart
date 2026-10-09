import 'dart:convert';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/features/tasks/data/models/task_model.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Stateless serializer designed to execute inside an isolated thread (Isolate.run).
class TaskDataSerializer {
  const TaskDataSerializer();

  /// Serializes tasks into standard JSON backup.
  static String toJsonString(
    List<Map<String, dynamic>> rawTasks,
    List<String>? categories, {
    String? appVersion,
    int? schemaVersion,
  }) {
    final effectiveAppVersion = appVersion ?? AppConfig.appVersion;
    final effectiveSchemaVersion = schemaVersion ?? AppConfig.schemaVersion;
    final payload = {
      'app': 'TodoApp',
      'appVersion': effectiveAppVersion,
      'version': effectiveAppVersion,
      'schemaVersion': effectiveSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories ?? const [],
      'tasksCount': rawTasks.length,
      'tasks': rawTasks,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Serializes tasks into RFC 4180 CSV format.
  static String toCsvString(List<Map<String, dynamic>> rawTasks) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'ID,Название,Описание,Категория,Приоритет,Статус,Срок выполнения,Дата создания,Дата завершения,Помодоро сессий,Минут фокуса,Подзадачи',
    );

    for (final t in rawTasks) {
      final id = t['id']?.toString() ?? '';
      final name = _escapeCsv(t['name']?.toString() ?? '');
      final desc = _escapeCsv(t['value']?.toString() ?? '');
      final cat = _escapeCsv(t['category']?.toString() ?? '');
      final pIndex = (t['priorityIndex'] as int?) ?? -1;
      final priority = _priorityLabel(pIndex);
      final isDone = (t['isCompleted'] as bool? ?? false)
          ? 'Выполнено'
          : 'В работе';
      final dueDate = t['dueDate']?.toString() ?? '';
      final createdAt = t['createdAt']?.toString() ?? '';
      final completedAt = t['completedAt']?.toString() ?? '';
      final pomodoro = t['pomodoroCount']?.toString() ?? '0';
      final focusMin = t['focusMinutes']?.toString() ?? '0';

      final rawSubtasks = t['subtasks'] as List<dynamic>? ?? const [];
      final subtasksText = _escapeCsv(
        rawSubtasks
            .map((s) {
              if (s is Map<String, dynamic>) {
                final isSubDone = s['isCompleted'] == true ? '[x]' : '[ ]';
                return '$isSubDone ${s['title']}';
              }
              return s.toString();
            })
            .join('; '),
      );

      buffer.writeln(
        '$id,$name,$desc,$cat,$priority,$isDone,$dueDate,$createdAt,$completedAt,$pomodoro,$focusMin,$subtasksText',
      );
    }

    return buffer.toString();
  }

  /// Serializes tasks into human-readable Markdown format (Obsidian / Notion compatible).
  static String toMarkdownString(List<Map<String, dynamic>> rawTasks) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('# 📋 Экспорт задач TodoApp');
    buffer.writeln(
      '*Дата экспорта: ${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}*',
    );
    buffer.writeln('*Всего задач: ${rawTasks.length}*\n');

    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in rawTasks) {
      final cat = (t['category'] as String?)?.trim();
      final key = (cat == null || cat.isEmpty) ? 'Общее' : cat;
      grouped.putIfAbsent(key, () => []).add(t);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('## 📁 ${entry.key} (${entry.value.length})');
      for (final t in entry.value) {
        final isDone = t['isCompleted'] as bool? ?? false;
        final check = isDone ? '[x]' : '[ ]';
        final name = t['name']?.toString() ?? 'Без названия';
        final pIndex = (t['priorityIndex'] as int?) ?? -1;
        final priorityBadge = _priorityMarkdownBadge(pIndex);
        final dueDateStr = t['dueDate'] != null ? ' 🗓 `${t['dueDate']}`' : '';

        buffer.writeln('- $check **$name** $priorityBadge$dueDateStr');

        final desc = (t['value'] as String?)?.trim();
        if (desc != null && desc.isNotEmpty) {
          buffer.writeln('  > $desc');
        }

        final rawSubtasks = t['subtasks'] as List<dynamic>? ?? const [];
        for (final s in rawSubtasks) {
          if (s is Map<String, dynamic>) {
            final sDone = s['isCompleted'] == true ? '[x]' : '[ ]';
            buffer.writeln('  - $sDone ${s['title']}');
          }
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Deserializes a raw JSON string into a list of parsed [Task] objects.
  static List<Task> fromJsonString(String jsonContent) {
    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Неверный формат бэкапа: корневой элемент должен быть объектом',
      );
    }

    final tasksList = decoded['tasks'];
    if (tasksList is! List<dynamic>) {
      throw const FormatException('Отсутствует массив "tasks" в файле бэкапа');
    }

    final result = <Task>[];
    for (final item in tasksList) {
      if (item is Map<String, dynamic>) {
        result.add(TaskModel.fromMap(item));
      }
    }

    return result;
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _priorityLabel(int pIndex) {
    switch (pIndex) {
      case 0:
        return 'Срочно (P1)';
      case 1:
        return 'Высокий (P2)';
      case 2:
        return 'Средний (P3)';
      case 3:
        return 'Низкий (P4)';
      default:
        return 'Без приоритета';
    }
  }

  static String _priorityMarkdownBadge(int pIndex) {
    switch (pIndex) {
      case 0:
        return '🔴 `P1 Срочно`';
      case 1:
        return '🟠 `P2 Высокий`';
      case 2:
        return '🟣 `P3 Средний`';
      case 3:
        return '🟢 `P4 Низкий`';
      default:
        return '';
    }
  }
}
