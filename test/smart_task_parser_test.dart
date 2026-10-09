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

    test(
      'converts conversational Russian slang into clean spoken task with subtask and category (шарага + похавать)',
      () {
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
      },
    );

    test(
      'splits multiple chained subtasks and strips filler words (так мне ехать в шарагу еще надо похавать и помыться)',
      () {
        final draft = parser.parse(
          'так мне ехать в шарагу через 3 часа еще надо похавать и помыться',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Ехать в шарагу');
        expect(draft.category, 'Учеба');
        expect(draft.dueDate, fixedTime.add(const Duration(hours: 3)));
        expect(draft.subtasks.length, 2);
        expect(draft.subtasks, containsAll(['Похавать', 'Помыться']));
      },
    );

    test(
      'normalizes colloquial prefixes (надо в зал, мне к стоматологу, сгонять в магазин)',
      () {
        final d1 = parser.parse(
          'надо в зал через час',
          referenceTime: fixedTime,
        );
        expect(d1.name, 'Пойти в зал');
        expect(d1.category, 'Спорт');

        final d2 = parser.parse(
          'мне к стоматологу завтра в 15:00',
          referenceTime: fixedTime,
        );
        expect(d2.name, 'Пойти к стоматологу');
        expect(d2.category, 'Здоровье');

        final d3 = parser.parse(
          'сгонять в магазин за хлебом',
          referenceTime: fixedTime,
        );
        expect(d3.name, 'Сходить в магазин за хлебом');
        expect(d3.category, 'Покупки');
      },
    );

    test(
      'normalizes 1st person future verbs to infinitive (позвоню риелтору, заберу заказ)',
      () {
        final d1 = parser.parse(
          'вечером позвоню риелтору насчет квартиры',
          referenceTime: fixedTime,
        );
        expect(d1.name, 'Позвонить риелтору');
        expect(d1.description, 'Насчет квартиры');
        expect(d1.category, 'Дом');
        expect(d1.dueDate?.hour, 18);

        final d2 = parser.parse(
          'после работы заберу заказ с озона, код в приложении',
          referenceTime: fixedTime,
        );
        expect(d2.name, 'Забрать заказ с озона');
        expect(d2.description, 'Код в приложении');
        expect(d2.category, 'Покупки');
      },
    );

    test(
      'extracts reason into description and handles colloquial time (стоматолог + а то болит)',
      () {
        final draft = parser.parse(
          'завтра часиков в 5 вечера сгонять к стоматологу почистить зубы а то пиздец болит',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Сходить к стоматологу почистить зубы');
        expect(draft.description, 'А то пиздец болит');
        expect(draft.dueDate, DateTime(2026, 10, 10, 17, 0));
        expect(draft.priorityIndex, 0); // Urgent because "пиздец болит"
        expect(draft.category, 'Здоровье');
      },
    );

    test(
      'handles compound multi-clause sentence with subtasks and colloquial time',
      () {
        final draft = parser.parse(
          'короче надо бы в зал часиков в 6 вечера, еще форму постирать и шейкер найти',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Пойти в зал');
        expect(draft.dueDate, DateTime(2026, 10, 9, 18, 0));
        expect(draft.category, 'Спорт');
        expect(draft.subtasks.length, 2);
        expect(
          draft.subtasks,
          containsAll(['Форму постирать', 'Шейкер найти']),
        );
      },
    );

    test(
      'benchmark: handles cleaning task with subtasks (убраться в хате: вынести мусор, помыть полы)',
      () {
        final draft = parser.parse(
          'надо убраться в хате перед приходом гостей: вынести мусор, помыть полы и протереть пыль',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Убраться в хате');
        expect(draft.category, 'Дом');
        expect(draft.subtasks.length, 3);
        expect(
          draft.subtasks,
          containsAll(['Вынести мусор', 'Помыть полы', 'Протереть пыль']),
        );
      },
    );

    test(
      'benchmark: handles car service and tire change (сгонять на шиномонтаж в субботу к 11)',
      () {
        final draft = parser.parse(
          'сгонять на шиномонтаж в субботу к 11, переобуть резину',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Сходить на шиномонтаж');
        expect(draft.category, 'Спорт'); // шиномонтаж / авто
        expect(draft.dueDate?.weekday, DateTime.saturday);
        expect(draft.dueDate?.hour, 11);
        expect(draft.subtasks, isNotEmpty);
        expect(draft.subtasks.first, 'Переобуть резину');
      },
    );

    test(
      'benchmark: handles urgent study deadline (завтра в 9 утра сдам курсач преподу, горит дедлайн)',
      () {
        final draft = parser.parse(
          'завтра в 9 утра сдам курсач преподу в универе, горит дедлайн',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Сдать курсач преподу в универе');
        expect(draft.category, 'Учеба');
        expect(draft.dueDate, DateTime(2026, 10, 10, 9, 0));
        expect(draft.priorityIndex, 0); // Urgent because "горит дедлайн"
      },
    );

    test(
      'benchmark: handles medical instructions note (мне к врачу завтра в 9:15 утра на голодный желудок)',
      () {
        final draft = parser.parse(
          'мне к врачу завтра в 9:15 утра на голодный желудок',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Пойти к врачу');
        expect(draft.category, 'Здоровье');
        expect(draft.description, 'На голодный желудок');
        expect(draft.dueDate, DateTime(2026, 10, 10, 9, 15));
      },
    );

    test(
      'benchmark: handles leisure event with shopping subtasks (в пятницу в 19:00 созвон с пацанами в дискорде)',
      () {
        final draft = parser.parse(
          'в пятницу в 19:00 созвон с пацанами в дискорде, еще купить чипсы и пиво',
          referenceTime: fixedTime,
        );

        expect(draft.name, 'Созвон с пацанами в дискорде');
        expect(draft.category, 'Личное');
        expect(draft.dueDate?.weekday, DateTime.friday);
        expect(draft.dueDate?.hour, 19);
        expect(draft.subtasks.length, 2);
        expect(draft.subtasks, containsAll(['Купить чипсы', 'Пиво']));
      },
    );

    test(
      'extracts explicit reminder offset in hours (напомнить за час, за 2 часа)',
      () {
        final draft1 = parser.parse(
          'так мне ехать в шарагу через 3 часа еще надо похавать и помыться и напомнить за час',
          referenceTime: fixedTime,
        );

        expect(draft1.reminderOffsetMinutes, 60);
        expect(draft1.subtasks.length, 2);
        expect(draft1.subtasks, containsAll(['Похавать', 'Помыться']));
        expect(draft1.name, 'Ехать в шарагу');

        final draft2 = parser.parse(
          'созвон в пятницу в 19:00, за 2 часа напомни',
          referenceTime: fixedTime,
        );

        expect(draft2.reminderOffsetMinutes, 120);
        expect(draft2.name.toLowerCase(), contains('созвон'));
      },
    );

    test(
      'extracts reminder offset in minutes (напомнить за 30 минут, за полчаса)',
      () {
        final draft1 = parser.parse(
          'завтра в 15:00 к стоматологу, напомнить за 30 минут',
          referenceTime: fixedTime,
        );

        expect(draft1.reminderOffsetMinutes, 30);
        expect(draft1.dueDate, DateTime(2026, 10, 10, 15, 0));

        final draft2 = parser.parse(
          'позвонить риелтору завтра в 12:00, напомни за полчаса',
          referenceTime: fixedTime,
        );

        expect(draft2.reminderOffsetMinutes, 30);
      },
    );

    test('respects explicit no-reminder instruction (без напоминания)', () {
      final draft = parser.parse(
        'завтра в 10:00 сдать курсач, без напоминания',
        referenceTime: fixedTime,
      );

      expect(draft.reminderOffsetMinutes, null);
      expect(draft.dueDate, DateTime(2026, 10, 10, 10, 0));
    });

    test(
      'defaults to 15 minutes reminder when date is set without explicit reminder',
      () {
        final draft = parser.parse(
          'завтра в 19:00 тренировка в зале',
          referenceTime: fixedTime,
        );

        expect(draft.reminderOffsetMinutes, 15);
      },
    );
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
