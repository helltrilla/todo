import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';

/// Comprehensive offline rule-based NLP parser that transforms free-form natural language,
/// conversational thoughts, slang, and compound utterances into clean structured tasks.
/// Works with zero latency and requires no network access or API keys.
class LocalNlpParser {
  const LocalNlpParser();

  SmartTaskDraft parse(
    String rawText, {
    DateTime? referenceTime,
    List<String>? availableCategories,
  }) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return const SmartTaskDraft(name: '', source: 'local_nlp');
    }

    final now = referenceTime ?? DateTime.now();

    // Stage 1: Extract multiline bullet subtasks (preserving lines)
    final (bulletSubtasks, textAfterBullets) = _extractBulletSubtasks(text);

    // Stage 2: Extract Date, Time & Relative Offsets
    final (dueDate, textWithoutDateTime) = _extractDateTime(
      textAfterBullets,
      now,
    );

    // Stage 2.5: Extract Reminder Offset ("напомнить за час", "за 30 минут", etc.)
    final (reminderOffsetMinutes, textWithoutReminder) = _extractReminder(
      textWithoutDateTime,
      dueDate != null,
    );

    // Stage 3: Extract Inline / Trigger / Chained Subtasks
    final (inlineSubtasks, textWithoutSubtasks) = _extractInlineSubtasks(
      textWithoutReminder,
    );
    final allSubtasks = [...bulletSubtasks, ...inlineSubtasks];

    // Stage 4: Extract Context, Reasons & Notes ("а то...", "код...", "терминал...")
    final (descriptions, textWithoutContext) = _extractContextAndNotes(
      textWithoutSubtasks,
    );

    // Stage 5: Extract Priority (urgent, high, low, contextual markers)
    final (priorityIndex, textWithoutPriority) = _extractPriority(
      textWithoutContext,
      text,
    );

    // Stage 6: Clean & Normalize Task Title (infinitive verbs, strip modals/fillers)
    final name = _cleanAndNormalizeTitle(textWithoutPriority, text);

    // Stage 7: Extract Category (prioritizing the normalized title, then full text)
    final category =
        _extractCategory(name, availableCategories ?? const []) ??
        _extractCategory(text, availableCategories ?? const []);

    return SmartTaskDraft(
      name: name.isNotEmpty ? name : text,
      description: descriptions.join('. '),
      dueDate: dueDate,
      reminderOffsetMinutes: reminderOffsetMinutes,
      priorityIndex: priorityIndex,
      category: category,
      subtasks: allSubtasks,
      source: 'local_nlp',
    );
  }

  static RegExp _wordRegExp(String innerPattern) {
    return RegExp(
      r'(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_])(?:' +
          innerPattern +
          r')(?=[^a-zA-Z0-9а-яА-ЯёЁ_]|$)',
      caseSensitive: false,
    );
  }

  // ===========================================================================
  // STAGE 1: MULTILINE BULLETS
  // ===========================================================================
  (List<String>, String) _extractBulletSubtasks(String text) {
    final lines = text.split('\n');
    if (lines.length <= 1) {
      return (const [], text);
    }

    final subtasks = <String>[];
    final preservedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final bulletMatch = RegExp(
        r'^(?:[-*•]|\d+[.)])\s+(.+)$',
      ).firstMatch(trimmed);
      if (bulletMatch != null) {
        final item = bulletMatch.group(1)!.trim();
        if (item.isNotEmpty) {
          subtasks.add(_cleanSubtaskItem(item));
        }
      } else {
        preservedLines.add(line);
      }
    }

    if (subtasks.isNotEmpty) {
      return (subtasks, preservedLines.join(' ').trim());
    }

    return (const [], text);
  }

  // ===========================================================================
  // STAGE 2: DATE & TIME EXTRACTION
  // ===========================================================================
  (DateTime?, String) _extractDateTime(String text, DateTime now) {
    var working = text;
    DateTime? targetDate;
    int? targetHour;
    int? targetMinute;

    // 1. Relative offsets: "через N часов", "через час", "через 30 минут", "через полчаса", "через день"
    final offsetMatch = _wordRegExp(
      r'через\s+(?:(\d+)\s+)?(минут[ыа]?|час[аов]?|дн[ейя]|день|недел[юьи]|полчаса)',
    ).firstMatch(working);

    if (offsetMatch != null) {
      final unit = (offsetMatch.group(2) ?? '').toLowerCase();
      final rawAmount = offsetMatch.group(1);
      final amount = rawAmount != null
          ? (int.tryParse(rawAmount) ?? 1)
          : (unit == 'полчаса' ? 30 : 1);

      if (unit == 'полчаса') {
        targetDate = now.add(const Duration(minutes: 30));
      } else if (unit.startsWith('мин')) {
        targetDate = now.add(Duration(minutes: amount));
      } else if (unit.startsWith('час')) {
        targetDate = now.add(Duration(hours: amount));
      } else if (unit.startsWith('дн') || unit.startsWith('ден')) {
        targetDate = now.add(Duration(days: amount));
      } else if (unit.startsWith('нед')) {
        targetDate = now.add(Duration(days: amount * 7));
      }
      working = working.replaceFirst(offsetMatch.group(0)!, ' ');
      return (targetDate, _cleanSpaces(working));
    }

    // 2. Exact Time: "15:30", "15.00", "в 15:30", "к 14:00", "в 9:15 утра"
    final exactTimeMatch = RegExp(
      r'(?:(?:примерно|где-то|около|часов|часиков)\s+)?(?:(?:в|к|с)\s+)?(\b\d{1,2})[:.-](\d{2})(?:\s*(?:утра|вечера|дня|ночи))?(?=[^а-яА-ЯёЁa-zA-Z0-9_]|$)',
      caseSensitive: false,
    ).firstMatch(working);

    if (exactTimeMatch != null) {
      targetHour = int.tryParse(exactTimeMatch.group(1)!);
      targetMinute = int.tryParse(exactTimeMatch.group(2)!);
      working = working.replaceFirst(exactTimeMatch.group(0)!, ' ');
    } else {
      // 3. Colloquial hours: "часиков в 5 вечера", "в 6 вечера", "к 10 утра", "с 9 утра", "в 15", "к 11"
      final phrasedHourMatch = RegExp(
        r'(?:(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_]))(?:(?:примерно|где-то|около|часов|часиков)\s+)?(?:в|к|с)\s+(\d{1,2})(?:\s*(утра|вечера|дня|ночи|час(?:а|ов)?))?(?=[^a-zA-Z0-9а-яА-ЯёЁ_]|$)',
        caseSensitive: false,
      ).firstMatch(working);

      if (phrasedHourMatch != null && phrasedHourMatch.group(1) != null) {
        final val = int.tryParse(phrasedHourMatch.group(1)!);
        if (val != null && val >= 0 && val <= 23) {
          final suffix = phrasedHourMatch.group(2)?.toLowerCase();
          if (suffix == 'вечера' && val < 12) {
            targetHour = val + 12;
          } else if (suffix == 'дня' && val < 12 && val >= 1) {
            targetHour = val + 12;
          } else if (suffix == 'ночи' && val >= 10) {
            targetHour = val;
          } else {
            targetHour = val;
          }
          targetMinute = 0;
          working = working.replaceFirst(phrasedHourMatch.group(0)!, ' ');
        }
      }
    }

    // 4. Absolute / Relative Days: "сегодня", "завтра", "послезавтра", "на выходных"
    final poslezavtra = _wordRegExp(r'послезавтра');
    final zavtra = _wordRegExp(r'завтра');
    final segodnya = _wordRegExp(r'сегодня');
    final vyhodnye = _wordRegExp(r'(?:на|в)\s+выходны[хе]');

    if (poslezavtra.hasMatch(working)) {
      targetDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 2));
      working = working.replaceAll(poslezavtra, ' ');
    } else if (zavtra.hasMatch(working)) {
      targetDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      working = working.replaceAll(zavtra, ' ');
    } else if (segodnya.hasMatch(working)) {
      targetDate = DateTime(now.year, now.month, now.day);
      working = working.replaceAll(segodnya, ' ');
    } else if (vyhodnye.hasMatch(working)) {
      var daysToSat = (DateTime.saturday - now.weekday) % 7;
      if (daysToSat <= 0) daysToSat += 7;
      targetDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: daysToSat));
      working = working.replaceAll(vyhodnye, ' ');
    }

    // 5. Weekdays: "в понедельник", "до пятницы", etc.
    final weekDayMap = {
      'понедельник': DateTime.monday,
      'пн': DateTime.monday,
      'вторник': DateTime.tuesday,
      'вт': DateTime.tuesday,
      'среду': DateTime.wednesday,
      'среда': DateTime.wednesday,
      'ср': DateTime.wednesday,
      'четверг': DateTime.thursday,
      'чт': DateTime.thursday,
      'пятницу': DateTime.friday,
      'пятница': DateTime.friday,
      'пт': DateTime.friday,
      'субботу': DateTime.saturday,
      'суббота': DateTime.saturday,
      'сб': DateTime.saturday,
      'воскресенье': DateTime.sunday,
      'вс': DateTime.sunday,
    };

    for (final entry in weekDayMap.entries) {
      final pattern = _wordRegExp('(?:в|во|до|к)?\\s*${entry.key}');
      if (pattern.hasMatch(working)) {
        final targetWeekday = entry.value;
        var daysToAdd = (targetWeekday - now.weekday) % 7;
        if (daysToAdd <= 0) daysToAdd += 7;
        targetDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: daysToAdd));
        working = working.replaceAll(pattern, ' ');
        break;
      }
    }

    // 6. Broad parts of day when no exact hour was specified:
    // "утром", "до обеда", "вечером", "после работы"
    if (targetHour == null) {
      final morning = _wordRegExp(r'(?:с\s+)?утр[ао]|утром');
      final afternoon = _wordRegExp(r'до\s+обеда|в\s+обед|днем');
      final evening = _wordRegExp(r'вечером|после\s+работы|до\s+вечера');

      if (morning.hasMatch(working)) {
        targetHour = 9;
        targetMinute = 0;
        working = working.replaceAll(morning, ' ');
      } else if (afternoon.hasMatch(working)) {
        targetHour = 13;
        targetMinute = 0;
        working = working.replaceAll(afternoon, ' ');
      } else if (evening.hasMatch(working)) {
        targetHour = 18;
        targetMinute = 0;
        working = working.replaceAll(evening, ' ');
      }
    }

    // Clean remaining loose temporal prepositions
    working = working.replaceAll(
      _wordRegExp(
        r'утром|вечером|днем|ночью|до\s+конца\s+недели|до\s+конца\s+месяца|на\s+следующей\s+неделе',
      ),
      ' ',
    );

    // Combine date and time
    if (targetDate != null || targetHour != null) {
      final baseDate = targetDate ?? DateTime(now.year, now.month, now.day);
      final hour = targetHour ?? (targetDate != null ? 12 : now.hour);
      final minute = targetMinute ?? 0;

      var result = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
      if (targetDate == null && result.isBefore(now)) {
        result = result.add(const Duration(days: 1));
      }
      return (result, _cleanSpaces(working));
    }

    return (null, _cleanSpaces(working));
  }

  // ===========================================================================
  // STAGE 2.5: REMINDER EXTRACTION
  // ===========================================================================
  (int?, String) _extractReminder(String text, bool hasDueDate) {
    var working = text;

    // 1. Explicit no-reminder: "без напоминания", "не напоминать", "без уведомлений"
    final noReminderMatch = RegExp(
      r'[,;]?\s*(?:(?:и|а)?\s*(?:мне\s+)?(?:не\s+надо\s+|не\s+нужно\s+|не\s+)?(?:напоминать|напоминай|напоминания|напоминаний|уведомлений|уведомления))|без\s+(?:напоминани[яй]|уведомлени[яй])',
      caseSensitive: false,
    ).firstMatch(working);
    if (noReminderMatch != null) {
      working = working.replaceFirst(noReminderMatch.group(0)!, ' ');
      return (null, _cleanDanglingPunctuation(working));
    }

    // 2. Reminder with explicit offset:
    // Pattern A: Trigger first, then duration:
    // e.g. "мне надо напомнить за час", "напомни за 1 час до этого", "напоминалку за 30 минут"
    final triggerFirstPattern = RegExp(
      r'[,;]?\s*(?:(?:и|а|еще|ещё|также)\s+)?(?:мне\s+)?(?:надо\s+|нужно\s+|бы\s+)*(?:напомнить|напомни|напомни-ка|напоминалку|напоминалка|напоминание|уведомить|уведоми|оповестить|оповести|поставить\s+напоминалку|поставь\s+напоминалку|кинуть\s+напоминалку|сделать\s+напоминалку)\s+(?:за\s+)?([а-яА-ЯёЁ0-9\s]+?)(?:\s+до\s+(?:этого|начала))?(?=[,;]|\s+(?:и|а|еще|ещё)\s+|$)',
      caseSensitive: false,
    );

    // Pattern B: Duration first, then trigger:
    // e.g. "за час напомнить", "за 30 минут до этого напомни", "за 2 часа уведомить"
    final durationFirstPattern = RegExp(
      r'[,;]?\s*(?:(?:и|а|еще|ещё|также)\s+)?за\s+([а-яА-ЯёЁ0-9\s]+?)(?:\s+до\s+(?:этого|начала))?\s+(?:напомнить|напомни|напомни-ка|напоминалку|напоминалка|напоминание|уведомить|уведоми|оповестить|оповести)(?=[,;]|\s+(?:и|а|еще|ещё)\s+|$)',
      caseSensitive: false,
    );

    // Pattern C: "с напоминанием за ..." / "напоминание за ..."
    final withReminderPattern = RegExp(
      r'[,;]?\s*(?:(?:и|а)\s+)?(?:с\s+напоминанием|напоминание|напоминалка|напоминалку)\s+за\s+([а-яА-ЯёЁ0-9\s]+?)(?:\s+до\s+(?:этого|начала))?(?=[,;]|\s+(?:и|а|еще|ещё)\s+|$)',
      caseSensitive: false,
    );

    for (final pattern in [
      triggerFirstPattern,
      durationFirstPattern,
      withReminderPattern,
    ]) {
      final match = pattern.firstMatch(working);
      if (match != null && match.group(1) != null) {
        final parsed = _parseReminderDurationMinutes(match.group(1)!);
        if (parsed != null) {
          working = working.replaceFirst(match.group(0)!, ' ');
          return (parsed, _cleanDanglingPunctuation(working));
        }
      }
    }

    return (hasDueDate ? 15 : null, _cleanDanglingPunctuation(working));
  }

  int? _parseReminderDurationMinutes(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s == 'час' ||
        s == '1 час' ||
        s == 'один час' ||
        s == 'часик' ||
        s == '1 ч' ||
        s == '1ч') {
      return 60;
    }
    if (s == '2 часа' ||
        s == 'два часа' ||
        s == 'пару часов' ||
        s == '2 ч' ||
        s == '2ч') {
      return 120;
    }
    if (s == '3 часа' || s == 'три часа' || s == '3 ч' || s == '3ч') {
      return 180;
    }
    if (s == 'полчаса' ||
        s == 'пол часа' ||
        s == 'пол-часа' ||
        s == '30 минут' ||
        s == '30 мин' ||
        s == 'тридцать минут') {
      return 30;
    }
    if (s == '15 минут' || s == '15 мин' || s == 'пятнадцать минут') {
      return 15;
    }
    if (s == '10 минут' || s == '10 мин' || s == 'десять минут') {
      return 10;
    }
    if (s == '5 минут' || s == '5 мин' || s == 'пять минут') {
      return 5;
    }
    if (s == '20 минут' || s == '20 мин' || s == 'двадцать минут') {
      return 20;
    }
    if (s == '45 минут' || s == '45 мин' || s == 'сорок пять минут') {
      return 45;
    }
    if (s == 'день' ||
        s == '1 день' ||
        s == 'один день' ||
        s == 'сутки' ||
        s == '1 сутки' ||
        s == '24 часа') {
      return 1440;
    }
    if (s == '2 дня' || s == 'два дня' || s == 'двое суток') {
      return 2880;
    }

    final hoursMatch = RegExp(r'^(\d+)\s*(?:час[аов]?|ч)$').firstMatch(s);
    if (hoursMatch != null) {
      return (int.tryParse(hoursMatch.group(1)!) ?? 1) * 60;
    }

    final minsMatch = RegExp(r'^(\d+)\s*мин(?:ут[а-я]*)?$').firstMatch(s);
    if (minsMatch != null) {
      return int.tryParse(minsMatch.group(1)!);
    }

    if (s.contains('момент') || s.contains('вовремя')) {
      return 0;
    }

    return null;
  }

  String _cleanDanglingPunctuation(String text) {
    var s = text.trim();
    s = s.replaceAll(RegExp(r'\s*,\s*,'), ',');
    s = s.replaceAll(RegExp(r'^[\s,;]+'), '');
    s = s.replaceAll(RegExp(r'[\s,;]+$'), '');
    return _cleanSpaces(s);
  }

  // ===========================================================================
  // STAGE 3: SUBTASK EXTRACTION & ACTION CHAINING
  // ===========================================================================
  (List<String>, String) _extractInlineSubtasks(String text) {
    final subtasks = <String>[];
    var working = text;

    // 1. Universal Colon Trigger:
    // e.g. "Купить продукты: молоко, хлеб, сыр и яблоки", "Убраться в хате перед гостями: вынести мусор, помыть полы"
    final colonIndex = working.indexOf(':');
    if (colonIndex != -1 && colonIndex > 3 && colonIndex < working.length - 3) {
      final afterColon = working.substring(colonIndex + 1).trim();
      var rawSplit = afterColon
          .split(RegExp(r'[,;]|\s+и\s+|\s+а также\s+', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      if (rawSplit.length >= 2) {
        final lastItem = rawSplit.last;
        final locMatch = RegExp(
          r'^(.+?)\s+(в|на|из|у|возле|около)\s+(.+)$',
          caseSensitive: false,
        ).firstMatch(lastItem);
        String? trailingLocation;
        if (locMatch != null) {
          rawSplit[rawSplit.length - 1] = locMatch.group(1)!.trim();
          trailingLocation = '${locMatch.group(2)} ${locMatch.group(3)}'.trim();
        }

        for (final item in rawSplit) {
          final clean = _cleanSubtaskItem(item);
          if (clean.isNotEmpty) {
            subtasks.add(clean);
          }
        }

        var baseText = working.substring(0, colonIndex).trim();
        // Remove trailing context phrases like "перед приходом гостей" if present before colon
        final eventContext = RegExp(
          r'\s+(?:перед|до)\s+(?:приход[а-яА-ЯёЁ\w\s]+|гост[а-яА-ЯёЁ\w\s]+)$',
          caseSensitive: false,
        ).firstMatch(baseText);
        if (eventContext != null) {
          baseText = baseText.substring(0, eventContext.start).trim();
        }

        if (trailingLocation != null) {
          baseText = '$baseText $trailingLocation';
        }
        return (subtasks, _cleanSpaces(baseText));
      }
    }

    // 2. Secondary subtask clauses:
    // e.g. "еще надо похавать и помыться", "а еще зайти в магаз и купить воды", "плюс сделать уроки"
    final secondaryClausePattern = RegExp(
      r'[,;]?\s+(?:а\s+|и\s+)?(?:еще|ещё|также|плюс|заодно|потом|успеть|перед\s+этим|до\s+этого|не\s+забыть\s+(?:бы\s+)?|по\s+дороге)\s+(.+)$',
      caseSensitive: false,
    );
    final secondaryMatch = secondaryClausePattern.firstMatch(working);
    if (secondaryMatch != null) {
      final clauseText = secondaryMatch.group(1)!.trim();
      final splitItems = clauseText
          .split(
            RegExp(
              r'[,;]|\s+и\s+|\s+а также\s+|\s+плюс\s+',
              caseSensitive: false,
            ),
          )
          .map((s) => _cleanSubtaskItem(s))
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      if (splitItems.isNotEmpty) {
        subtasks.addAll(splitItems);
        final base = working.substring(0, secondaryMatch.start).trim();
        return (subtasks, _cleanSpaces(base));
      }
    }

    // 3. Single secondary action separated by comma with infinitive verb:
    // e.g. "сгонять на шиномонтаж в субботу к 11, переобуть резину"
    final singleInfinitiveMatch = RegExp(
      r'[,;]\s+([а-яА-ЯёЁa-zA-Z]+(?:ть|ти|ться|тись|чь)\s+[^,;]+)$',
      caseSensitive: false,
    ).firstMatch(working);
    if (singleInfinitiveMatch != null) {
      final actionText = singleInfinitiveMatch.group(1)!.trim();
      final clean = _cleanSubtaskItem(actionText);
      if (clean.isNotEmpty) {
        subtasks.add(clean);
        final base = working.substring(0, singleInfinitiveMatch.start).trim();
        return (subtasks, _cleanSpaces(base));
      }
    }

    // 4. Patterns ending in "до этого" or "перед этим"
    final endingActionPattern = RegExp(
      r'[,;]?\s+(?:и\s+)(.+?)\s+(?:до\s+этого|перед\s+этим)$',
      caseSensitive: false,
    );
    final endingMatch = endingActionPattern.firstMatch(working);
    if (endingMatch != null) {
      final actionText = endingMatch.group(1)!.trim();
      final clean = _cleanSubtaskItem(actionText);
      if (clean.isNotEmpty) {
        subtasks.add(clean);
        final base = working.substring(0, endingMatch.start).trim();
        return (subtasks, _cleanSpaces(base));
      }
    }

    // 5. Inline triggers without colon: e.g. "взять форму и шейкер"
    final inlineTrigger = RegExp(
      r'(?:(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_]))(взять|не\s+забыть|купить)\s+([a-zA-Zа-яА-ЯёЁ0-9\s,;]+(?:,|(?:\s+и\s+))[a-zA-Zа-яА-ЯёЁ0-9\s,;]+)',
      caseSensitive: false,
    );

    final inlineMatch = inlineTrigger.firstMatch(working);
    if (inlineMatch != null) {
      final itemsStr = inlineMatch.group(2)!.trim();
      final splitItems = itemsStr
          .split(RegExp(r'[,;]|\s+и\s+|\s+а также\s+', caseSensitive: false))
          .map((s) => _cleanSubtaskItem(s))
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      if (splitItems.length >= 2) {
        subtasks.addAll(splitItems);
        working = working.replaceFirst(inlineMatch.group(0)!, ' ');
        return (subtasks, _cleanSpaces(working));
      }
    }

    return (subtasks, _cleanSpaces(working));
  }

  String _cleanSubtaskItem(String raw) {
    var item = raw.trim();

    // Strip leading modals
    item = item.replaceFirst(
      RegExp(
        r'^(?:надо|нужно|необходимо|бы|было\s+бы\s+неплохо|успеть|не\s+забыть)\s+',
        caseSensitive: false,
      ),
      '',
    );

    // Strip trailing modals
    item = item.replaceAll(
      RegExp(r'\s+(?:надо|нужно|бы|было\s+бы)$', caseSensitive: false),
      '',
    );

    // Strip trailing temporal markers
    item = item.replaceFirst(
      RegExp(r'\s+(?:до\s+этого|перед\s+этим)$', caseSensitive: false),
      '',
    );

    return _capitalize(item.trim());
  }

  // ===========================================================================
  // STAGE 4: REASONS, CONTEXT & NOTES EXTRACTION
  // ===========================================================================
  (List<String>, String) _extractContextAndNotes(String text) {
    final descriptions = <String>[];
    var working = text;

    // 1. Explanations / Reasons: "а то ...", "потому что ...", "так как ..."
    final reasonMatch = RegExp(
      r'[,;]?\s+(а\s+то(?:\s+.+)?|потому\s+что(?:\s+.+)?|так\s+как(?:\s+.+)?|иначе(?:\s+.+)?|ведь(?:\s+.+)?)$',
      caseSensitive: false,
    ).firstMatch(working);

    if (reasonMatch != null) {
      final reasonText = reasonMatch.group(1)!.trim();
      if (reasonText.length > 3) {
        descriptions.add(_capitalize(reasonText));
      }
      working = working.substring(0, reasonMatch.start).trim();
    }

    // 2. Extra notes: "код 1234", "код в приложении", "терминал б", "на голодный желудок", "насчет квартиры"
    final noteMatch = RegExp(
      r'[,;]?\s+(код\s+[:в0-9а-яА-ЯёЁ\w\s]+|терминал\s+[\wа-яА-ЯёЁ]+|на\s+голодный\s+желудок|насчет\s+[\wа-яА-ЯёЁ\s]+)$',
      caseSensitive: false,
    ).firstMatch(working);

    if (noteMatch != null) {
      final noteText = noteMatch.group(1)!.trim();
      descriptions.add(_capitalize(noteText));
      working = working.substring(0, noteMatch.start).trim();
    }

    return (descriptions, _cleanSpaces(working));
  }

  // ===========================================================================
  // STAGE 5: PRIORITY EXTRACTION
  // ===========================================================================
  (int, String) _extractPriority(String workingText, String originalText) {
    var working = workingText;

    // P1 — Urgent (0)
    final urgentRegex = _wordRegExp(
      r'очень\s+срочно|горит\s+дедлайн|дедлайн\s+горит|пиздец\s+болит|срочно|горит|неотложно|важно|критично|дедлайн|asap|urgent|critical|p1|п1',
    );
    if (urgentRegex.hasMatch(originalText)) {
      working = working.replaceAll(urgentRegex, ' ');
      return (0, _cleanSpaces(working));
    }

    // P2 — High (1)
    final highRegex = _wordRegExp(
      r'высокий\s+приоритет|быстрее|поскорее|дедлайн|успеть|не\s+опоздать|скорее|high|p2|п2',
    );
    if (highRegex.hasMatch(originalText)) {
      working = working.replaceAll(highRegex, ' ');
      return (1, _cleanSpaces(working));
    }

    // P4 — Low (3)
    final lowRegex = _wordRegExp(
      r'низкий\s+приоритет|не\s+к\s+спеху|когда[- ]?нибудь|потом|несрочно|вообще\s+не\s+к\s+спеху|low|p4|п4',
    );
    if (lowRegex.hasMatch(originalText)) {
      working = working.replaceAll(lowRegex, ' ');
      return (3, _cleanSpaces(working));
    }

    // P3 — Medium (2)
    final mediumRegex = _wordRegExp(r'средний\s+приоритет|medium|p3|п3');
    if (mediumRegex.hasMatch(originalText)) {
      working = working.replaceAll(mediumRegex, ' ');
      return (2, _cleanSpaces(working));
    }

    return (-1, _cleanSpaces(working));
  }

  // ===========================================================================
  // STAGE 6: TITLE CLEANING & CONVERSATIONAL NORMALIZATION
  // ===========================================================================
  String _cleanAndNormalizeTitle(String cleanedText, String originalText) {
    var text = _cleanSpaces(cleanedText);

    // 1. Strip conversational filler starters: "так", "короче", "в общем", "слушай", "ну", "давай"
    text = text.replaceFirst(
      RegExp(
        r'^(?:так|так-с|так\s+вот|короче|короче\s+говоря|кароче|короч|крч|в\s+общем|вобщем|слушай|значит|ну|ну-ка|типа|давай)\s*[,:;-]?\s*',
        caseSensitive: false,
      ),
      '',
    );

    // 2. Strip modal particles: "мне бы", "надо бы", "хотелось бы", "бы"
    text = text.replaceFirst(
      RegExp(
        r'^(?:мне\s+бы|надо\s+бы|нужно\s+бы|хотелось\s+бы|бы)\s+',
        caseSensitive: false,
      ),
      '',
    );

    // 3. Normalize 1st person future verbs to natural infinitive Reminders format:
    // e.g. "позвоню" -> "Позвонить", "заберу" -> "Забрать", "уберусь" -> "Убраться"
    final firstPersonMap = {
      'позвоню': 'Позвонить',
      'созвонюсь': 'Созвониться',
      'созвонимся': 'Созвониться',
      'встречу': 'Встретить',
      'встретимся': 'Встретиться',
      'напишу': 'Написать',
      'схожу': 'Сходить',
      'пойду': 'Пойти',
      'поеду': 'Поехать',
      'заеду': 'Заехать',
      'зайду': 'Зайти',
      'сдам': 'Сдать',
      'куплю': 'Купить',
      'заберу': 'Забрать',
      'уберусь': 'Убраться',
      'помою': 'Помыть',
      'постираю': 'Постирать',
      'починю': 'Починить',
      'допишу': 'Дописать',
      'скину': 'Скинуть',
      'отправлю': 'Отправить',
      'посмотрю': 'Посмотреть',
      'прочитаю': 'Прочитать',
      'приготовлю': 'Приготовить',
      'запишусь': 'Записаться',
      'оплачу': 'Оплатить',
      'соберусь': 'Собраться',
    };

    for (final entry in firstPersonMap.entries) {
      final verbRegex = RegExp(
        '^${entry.key}(?=[^а-яА-ЯёЁa-zA-Z0-9_]|\$)',
        caseSensitive: false,
      );
      if (verbRegex.hasMatch(text)) {
        text = text.replaceFirst(verbRegex, entry.value);
        break;
      }
    }

    // 4. "мне [инфинитив]" -> "[Инфинитив]" (e.g. "мне ехать в шарагу" -> "Ехать в шарагу")
    final infinitivePattern = RegExp(
      r'^(?:мне\s+)?([а-яА-ЯёЁa-zA-Z]+(?:ть|ти|ться|тись|чь))(?=[^а-яА-ЯёЁa-zA-Z0-9_]|$)\s*(.*)$',
      caseSensitive: false,
    );
    final infMatch = infinitivePattern.firstMatch(text);
    if (infMatch != null && text.toLowerCase().startsWith('мне ')) {
      final verb = infMatch.group(1)!;
      final rest = infMatch.group(2)!.trim();
      text = rest.isNotEmpty ? '$verb $rest' : verb;
    }

    // 5. "мне в/на/к [X]" or "надо в/на/к [X]" -> "Пойти в/на/к [X]"
    final goToPattern = RegExp(
      r'^(?:мне|надо|нужно|пора|собираюсь|планирую|хочу)\s+(в|на|к)\s+(.+)$',
      caseSensitive: false,
    );
    final goToMatch = goToPattern.firstMatch(text);
    if (goToMatch != null) {
      final prep = goToMatch.group(1)!.toLowerCase();
      final destination = goToMatch.group(2)!.trim();
      text = 'Пойти $prep $destination';
    } else {
      final bareDestPattern = RegExp(
        r'^(в|на|к)\s+([а-яА-ЯёЁ\w\s]+)$',
        caseSensitive: false,
      );
      final bareDestMatch = bareDestPattern.firstMatch(text);
      if (bareDestMatch != null) {
        final prep = bareDestMatch.group(1)!.toLowerCase();
        final destination = bareDestMatch.group(2)!.trim();
        text = 'Пойти $prep $destination';
      }
    }

    // 6. Strip leading modals: "надо", "нужно", "хочу", "не забыть"
    text = text.replaceFirst(
      RegExp(
        r'^(?:мне\s+)?(?:надо|нужно|необходимо|хочу|пора|планирую|задача:?)\s+',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'^не\s+забыть\s+(?:бы\s+)?', caseSensitive: false),
      '',
    );

    // 7. "сгонять в/на/к [X]" -> "Сходить в/на/к [X]"
    text = text.replaceFirstMapped(
      RegExp(
        r'^(?:сгонять|сбегать|заскочить)\s+(в|на|к)\s+',
        caseSensitive: false,
      ),
      (m) => 'Сходить ${m.group(1)} ',
    );

    // 8. "успеть [делать]" -> "[Делать]"
    text = text.replaceFirst(RegExp(r'^успеть\s+', caseSensitive: false), '');

    // 9. Clean dangling prepositions or trailing conjunctions
    text = text.replaceAll(
      RegExp(
        r'\s+(?:и|а|а\s+то|до|перед|к|в|на|с|со|по|насчет)\s*$',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'[,;:\s]+$'), '');

    var title = _capitalize(text.trim());

    if (title.length < 3) {
      title = _capitalize(originalText.trim());
    }

    return title;
  }

  // ===========================================================================
  // STAGE 7: CONTEXTUAL CATEGORY MAPPING
  // ===========================================================================
  String? _extractCategory(String text, List<String> availableCategories) {
    final lower = text.toLowerCase();

    // Check existing custom categories first
    for (final cat in availableCategories) {
      if (cat == 'Все' || cat == 'Общее') continue;
      if (lower.contains(cat.toLowerCase())) {
        return cat;
      }
    }

    const ru = r'[а-яА-ЯёЁ]*';

    // Comprehensive category lexicon
    if (_wordRegExp(
      'универ$ru|шараг$ru|колледж$ru|техникум$ru|инстик$ru|институт$ru|пар[ыаеи]|парам$ru|лекци$ru|семинар$ru|лаб[ыаеи]$ru|лабораторн$ru|экзамен$ru|зачет$ru|сесси$ru|дз|домашк$ru|учеб$ru|книг$ru|стать$ru|курс$ru|урок$ru|курсач$ru|диплом$ru|препод$ru|школ$ru|матан$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Учеба', 'Study');
    }
    if (_wordRegExp(
      'спорт$ru|тренировк$ru|треня$ru|трен[юе]$ru|зал$ru|качалк$ru|бег$ru|пробежк$ru|бассейн$ru|фитнес$ru|жим|разминк$ru|турник$ru|шейкер$ru|воркаут$ru|шиномонтаж$ru|переобуть$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Спорт', 'Sport');
    }
    if (_wordRegExp(
      'дискорд$ru|тусовк$ru|туса|вписк$ru|бар|паб|кафе$ru|рестик$ru|гулять|прогулк$ru|пацан$ru|друзь$ru|друг$ru|девушк$ru|парикмахер$ru|барбер$ru|стрижк$ru|кино|фильм|садик$ru|аэропорт$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Личное', 'Personal');
    }
    if (_wordRegExp(
      'купить|покупк$ru|магазин$ru|магаз$ru|продукт$ru|шоппинг|заказать|доставк$ru|рынок|супермаркет$ru|похавать|поесть|перекусить|еда|хавчик$ru|озон$ru|вб|сдэк$ru|заказ$ru|пицц$ru|мак[еа]?',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Покупки', 'Shopping');
    }
    if (_wordRegExp(
      'врач$ru|стоматолог$ru|доктор$ru|аптек$ru|таблетк$ru|анализ$ru|больниц$ru|клиник$ru|здоровь$ru|осмотр$ru|лекарств$ru|поликлиник$ru|зуб$ru|чистк$ru|обезбол$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Здоровье', 'Health');
    }
    if (_wordRegExp(
      'работ$ru|отчет$ru|митинг$ru|созвон$ru|клиент$ru|проект$ru|руководств$ru|начальник$ru|дедлайн$ru|договор$ru|офис$ru|смен[аеы]|таск$ru|слак$ru|резюме$ru|правк$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Работа', 'Work');
    }
    if (_wordRegExp(
      'уборк$ru|убраться|постирать|помыть|ремонт$ru|дом$ru|квартир$ru|хат[аеы]$ru|сантехник$ru|посуд$ru|мусор$ru|кран$ru|дач[аеу]$ru|интернет$ru',
    ).hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Дом', 'Home');
    }

    return null;
  }

  String _findBestMatch(
    List<String> available,
    String preferredRu,
    String preferredEn,
  ) {
    for (final cat in available) {
      if (cat.toLowerCase() == preferredRu.toLowerCase() ||
          cat.toLowerCase() == preferredEn.toLowerCase()) {
        return cat;
      }
    }
    return preferredRu;
  }

  String _cleanSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
