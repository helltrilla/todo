import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/data/services/local_nlp_parser.dart';
import 'package:todo/features/tasks/data/services/smart_task_parser_impl.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';

void main() {
  group('LocalNlpParser (Offline Natural Language Engine)', () {
    const parser = LocalNlpParser();
    final fixedTime = DateTime(2026, 10, 9, 10, 0); // Friday, 10:00 AM

    test('extracts urgent priority, time, and doctor category', () {
      final draft = parser.parse(
        'Завтра в 15:00 сходить к стоматологу на осмотр, очень срочно',
        referenceTime: fixedTime,
      );

      expect(draft.priorityIndex, 0); // P1 Urgent
      expect(draft.dueDate, DateTime(2026, 10, 10, 15, 0));
      expect(draft.category, 'Здоровье');
      expect(draft.name.toLowerCase(), contains('стоматолог'));
    });

    test('extracts subtasks from list trigger with commas and "и"', () {
      final draft = parser.parse(
        'Купить продукты: молоко, хлеб, сыр и яблоки в супермаркете',
        referenceTime: fixedTime,
      );

      expect(draft.category, 'Покупки');
      expect(draft.subtasks.length, 4);
      expect(draft.subtasks, containsAll(['Молоко', 'Хлеб', 'Сыр', 'Яблоки']));
    });

    test('extracts weekday, high priority, and work context', () {
      final draft = parser.parse(
        'В понедельник в 11:00 созвон по проекту, высокий приоритет',
        referenceTime: fixedTime,
      );

      expect(draft.priorityIndex, 1); // P2 High
      expect(draft.dueDate?.weekday, DateTime.monday);
      expect(draft.dueDate?.hour, 11);
      expect(draft.category, 'Работа');
    });

    test('extracts bulleted checklist items accurately', () {
      final draft = parser.parse(
        'Собрать чемодан в поездку:\n- Паспорт и билеты\n- Зарядка для телефона\n- Теплая куртка',
        referenceTime: fixedTime,
      );

      expect(draft.subtasks.length, 3);
      expect(draft.subtasks[0], 'Паспорт и билеты');
      expect(draft.subtasks[1], 'Зарядка для телефона');
      expect(draft.subtasks[2], 'Теплая куртка');
    });

    test('extracts relative time offset (через 2 часа)', () {
      final draft = parser.parse(
        'Позвонить маме через 2 часа',
        referenceTime: fixedTime,
      );

      expect(draft.dueDate, fixedTime.add(const Duration(hours: 2)));
    });

    test('respects low priority (не к спеху / потом)', () {
      final draft = parser.parse(
        'Разобрать старые вещи на балконе, не к спеху',
        referenceTime: fixedTime,
      );

      expect(draft.priorityIndex, 3); // P4 Low
    });

    test('converts conversational Russian slang into clean spoken task with subtask and category (шарага + похавать)', () {
      final draft = parser.parse(
        'мне в шарагу через 3 часа и успеть похавать до этого',
        referenceTime: fixedTime,
      );

      expect(draft.name, 'Пойти в шарагу');
      expect(draft.category, 'Учеба');
      expect(draft.subtasks, isNotEmpty);
      expect(draft.subtasks.first.toLowerCase(), contains('похавать'));
      expect(draft.dueDate, fixedTime.add(const Duration(hours: 3)));
      expect(draft.priorityIndex, 1); // High priority because of "успеть"
    });

    test('normalizes colloquial prefixes (надо в зал, мне к стоматологу, сгонять в магазин)', () {
      final d1 = parser.parse('надо в зал через час', referenceTime: fixedTime);
      expect(d1.name, 'Пойти в зал');
      expect(d1.category, 'Спорт');

      final d2 = parser.parse('мне к стоматологу завтра в 15:00', referenceTime: fixedTime);
      expect(d2.name, 'Пойти к стоматологу');
      expect(d2.category, 'Здоровье');

      final d3 = parser.parse('сгонять в магазин за хлебом', referenceTime: fixedTime);
      expect(d3.name, 'Сходить в магазин за хлебом');
      expect(d3.category, 'Покупки');
    });
  });

  group('SmartTaskParserImpl Service', () {
    late SharedPreferences prefs;
    late SmartTaskParserImpl parser;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      parser = SmartTaskParserImpl(prefs: prefs);
    });

    test('manages Gemini API key in SharedPreferences', () async {
      expect(parser.hasGeminiApiKey, false);
      expect(parser.getGeminiApiKey(), null);

      await parser.setGeminiApiKey('AIzaSyTestKey123');
      expect(parser.hasGeminiApiKey, true);
      expect(parser.getGeminiApiKey(), 'AIzaSyTestKey123');

      await parser.setGeminiApiKey(null);
      expect(parser.hasGeminiApiKey, false);
      expect(parser.getGeminiApiKey(), null);
    });

    test('falls back to local NLP when offline or no API key', () async {
      final result = await parser.parseTaskPrompt(
        'Завтра в 19:00 тренировка в зале, взять форму и шейкер',
        referenceTime: DateTime(2026, 10, 9, 12, 0),
      );

      expect(result, isA<Success<SmartTaskDraft>>());
      final draft = (result as Success<SmartTaskDraft>).data;
      expect(draft.name, isNotEmpty);
      expect(draft.dueDate?.hour, 19);
      expect(draft.subtasks, isNotEmpty);
      expect(draft.category, 'Спорт');
    });
  });
}
