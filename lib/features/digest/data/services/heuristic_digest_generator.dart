import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class HeuristicDigestGenerator {
  const HeuristicDigestGenerator();

  DailyDigest generate({
    required List<Task> tasks,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final activeTasks = tasks.where((t) => !t.isArchived).toList();
    final pendingTasks = activeTasks.where((t) => !t.isCompleted).toList();
    final completedToday = activeTasks.where((t) => t.isCompleted).length;

    if (activeTasks.isEmpty) {
      return DailyDigest(
        headline: 'Чистый лист на сегодня',
        topFocus: 'Стратегическое планирование и отдых',
        productivitySlot: 'Свободный график',
        summary:
            'У вас пока нет активных задач. Запланируйте ключевые цели или посвятите день восстановлению ресурсов.',
        generatedAt: now,
        isFallback: true,
      );
    }

    if (pendingTasks.isEmpty) {
      return DailyDigest(
        headline: 'Все задачи закрыты! 🚀',
        topFocus: 'Фиксация результатов и перезагрузка',
        productivitySlot: 'Свободное время',
        summary:
            'Великолепная продуктивность: закрыто задач — $completedToday. Самое время передохнуть или наметить шаги на завтра.',
        generatedAt: now,
        isFallback: true,
      );
    }

    // Sort pending tasks: prioritize priorityIndex (0=P1, 1=P2), then due date
    final sorted = List<Task>.from(pendingTasks)
      ..sort((a, b) {
        final prioA = a.priorityIndex >= 0 ? a.priorityIndex : 99;
        final prioB = b.priorityIndex >= 0 ? b.priorityIndex : 99;
        if (prioA != prioB) return prioA.compareTo(prioB);
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return 0;
      });

    final topTask = sorted.first;
    final urgentCount = pendingTasks.where((t) => t.priorityIndex == 0 || t.priorityIndex == 1).length;

    final String slotRecommendation;
    final currentHour = now.hour;
    if (currentHour < 12) {
      slotRecommendation = '10:00 – 12:30 (утренний пик энергии)';
    } else if (currentHour < 17) {
      slotRecommendation = '14:30 – 16:30 (глубокий фокус)';
    } else {
      slotRecommendation = '18:30 – 20:30 (вечерний спринт)';
    }

    final headline = urgentCount > 0
        ? 'Фокус дня: $urgentCount задач с высоким приоритетом'
        : 'Утренний бриф: ${pendingTasks.length} активных задач';

    final categoryContext = topTask.category.isNotEmpty && topTask.category != 'Общее'
        ? ' в категории «${topTask.category}»'
        : '';

    final summary =
        'В списке ${pendingTasks.length} задач на сегодня. Ключевая цель — «${topTask.name}»$categoryContext. '
        'Рекомендуем взять её в первом фокус-спринте Pomodoro, чтобы задать победный темп всему дню.';

    return DailyDigest(
      headline: headline,
      topFocus: topTask.name,
      productivitySlot: slotRecommendation,
      summary: summary,
      generatedAt: now,
      isFallback: true,
    );
  }
}
