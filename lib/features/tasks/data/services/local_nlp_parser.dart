import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';

/// Offline rule-based NLP parser that extracts structured tasks from natural language.
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

    // 1. Extract multiline bullets first while newlines are intact
    final (bulletSubtasks, textAfterBullets) = _extractBulletSubtasks(text);

    // 2. Extract Date & Time (including relative offsets)
    final (dueDate, textWithoutDateTime) = _extractDateTime(
      textAfterBullets,
      now,
    );

    // 3. Extract Priority
    final (priorityIndex, textWithoutPriority) = _extractPriority(
      textWithoutDateTime,
    );

    // 4. Extract Inline / Trigger / Chained Subtasks
    final (inlineSubtasks, textWithoutSubtasks) = _extractInlineSubtasks(
      textWithoutPriority,
    );
    final allSubtasks = [...bulletSubtasks, ...inlineSubtasks];

    // 5. Extract Category (from full input to maintain context)
    final category = _extractCategory(
      text,
      availableCategories ?? const [],
    );

    // 6. Clean Title with Conversational Russian Normalizer
    final (name, description) = _cleanTitleAndDescription(
      textWithoutSubtasks,
      text,
    );

    return SmartTaskDraft(
      name: name.isNotEmpty ? name : text,
      description: description,
      dueDate: dueDate,
      reminderOffsetMinutes: dueDate != null ? 15 : null,
      priorityIndex: priorityIndex,
      category: category,
      subtasks: allSubtasks,
      source: 'local_nlp',
    );
  }

  static RegExp _wordRegExp(String innerPattern) {
    return RegExp(
      r'(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_])(?:' + innerPattern + r')(?=[^a-zA-Z0-9а-яА-ЯёЁ_]|$)',
      caseSensitive: false,
    );
  }

  (List<String>, String) _extractBulletSubtasks(String text) {
    final lines = text.split('\n');
    if (lines.length <= 1) {
      return (const [], text);
    }

    final subtasks = <String>[];
    final preservedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final bulletMatch = RegExp(r'^(?:[-*•]|\d+[.)])\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final item = bulletMatch.group(1)!.trim();
        if (item.isNotEmpty) {
          subtasks.add(_capitalize(item));
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

  (int, String) _extractPriority(String text) {
    var working = text;

    // P1 — Urgent (0)
    final urgent = _wordRegExp(r'очень\s+срочно|срочно|горит|неотложно|важно|критично|asap|urgent|critical|p1|п1');
    if (urgent.hasMatch(working)) {
      working = working.replaceAll(urgent, ' ');
      return (0, _cleanSpaces(working));
    }

    // P2 — High (1)
    final explicitHigh = _wordRegExp(r'высокий\s+приоритет|быстрее|поскорее|high|p2|п2');
    if (explicitHigh.hasMatch(working)) {
      working = working.replaceAll(explicitHigh, ' ');
      return (1, _cleanSpaces(working));
    }

    // Contextual High signals like "успеть", "не опоздать" (do not strip from working if part of phrase)
    final contextualHigh = _wordRegExp(r'успеть|не\s+опоздать|скорее');
    if (contextualHigh.hasMatch(working)) {
      return (1, working);
    }

    // P4 — Low (3)
    final low = _wordRegExp(r'низкий\s+приоритет|не\s+к\s+спеху|когда[- ]?нибудь|потом|несрочно|low|p4|п4');
    if (low.hasMatch(working)) {
      working = working.replaceAll(low, ' ');
      return (3, _cleanSpaces(working));
    }

    // P3 — Medium (2)
    final medium = _wordRegExp(r'средний\s+приоритет|medium|p3|п3');
    if (medium.hasMatch(working)) {
      working = working.replaceAll(medium, ' ');
      return (2, _cleanSpaces(working));
    }

    return (-1, working);
  }

  (DateTime?, String) _extractDateTime(String text, DateTime now) {
    var working = text;
    DateTime? targetDate;
    int? targetHour;
    int? targetMinute;

    // 1. Relative offsets FIRST: "через N часов", "через час", "через 30 минут", "через полчаса", "через день"
    final offsetMatch = _wordRegExp(
      r'через\s+(?:(\d+)\s+)?(минут[ыа]?|час[аов]?|дн[ейя]|день|недел[юьи]|полчаса)',
    ).firstMatch(working);

    if (offsetMatch != null) {
      final unit = (offsetMatch.group(2) ?? '').toLowerCase();
      final rawAmount = offsetMatch.group(1);
      final amount = rawAmount != null ? (int.tryParse(rawAmount) ?? 1) : (unit == 'полчаса' ? 30 : 1);

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

    // 2. Specific Time: "15:30", "15-30", "15.00", "в 15:00"
    final timeMatch = RegExp(
      r'(?:(?:в|к)\s+)?(\b\d{1,2})[:.-](\d{2})\b',
      caseSensitive: false,
    ).firstMatch(working);

    if (timeMatch != null) {
      targetHour = int.tryParse(timeMatch.group(1)!);
      targetMinute = int.tryParse(timeMatch.group(2)!);
      working = working.replaceFirst(timeMatch.group(0)!, ' ');
    } else {
      // 3. Phrased hour: "в 9 утра", "в 8 вечера", "в 15", "к 11 часам", "в 11:00"
      final phrasedHourMatch = RegExp(
        r'(?:(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_]))(?:в|к)\s+(\d{1,2})(?:\s*(утра|вечера|дня|ночи|час(?:а|ов)?))?(?=[^a-zA-Z0-9а-яА-ЯёЁ_]|$)',
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

    // 4. Absolute Days: "сегодня", "завтра", "послезавтра"
    final poslezavtra = _wordRegExp(r'послезавтра');
    final zavtra = _wordRegExp(r'завтра');
    final segodnya = _wordRegExp(r'сегодня');

    if (poslezavtra.hasMatch(working)) {
      targetDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
      working = working.replaceAll(poslezavtra, ' ');
    } else if (zavtra.hasMatch(working)) {
      targetDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      working = working.replaceAll(zavtra, ' ');
    } else if (segodnya.hasMatch(working)) {
      targetDate = DateTime(now.year, now.month, now.day);
      working = working.replaceAll(segodnya, ' ');
    }

    // 5. Days of week: "в понедельник", "во вторник", "в среду", etc.
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
      final pattern = _wordRegExp('(?:в|во)?\\s*${entry.key}');
      if (pattern.hasMatch(working)) {
        final targetWeekday = entry.value;
        var daysToAdd = (targetWeekday - now.weekday) % 7;
        if (daysToAdd <= 0) daysToAdd += 7;
        targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));
        working = working.replaceAll(pattern, ' ');
        break;
      }
    }

    // Combine date and time
    if (targetDate != null || targetHour != null) {
      final baseDate = targetDate ?? DateTime(now.year, now.month, now.day);
      final hour = targetHour ?? (targetDate != null ? 12 : now.hour);
      final minute = targetMinute ?? 0;

      var result = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      if (targetDate == null && result.isBefore(now)) {
        result = result.add(const Duration(days: 1));
      }
      return (result, _cleanSpaces(working));
    }

    return (null, _cleanSpaces(working));
  }

  (List<String>, String) _extractInlineSubtasks(String text) {
    final subtasks = <String>[];
    var working = text;

    // 1. Colon trigger: e.g. "Купить продукты: молоко, хлеб, сыр и яблоки в супермаркете"
    final triggerPattern = RegExp(
      r'(?:(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_]))(купить|взять|сделать|шаги|чек-лист|подзадачи|не\s+забыть|продукты)\s*[:]\s*(.+)$',
      caseSensitive: false,
    );

    final match = triggerPattern.firstMatch(working);

    if (match != null) {
      final itemsStr = match.group(2)!.trim();
      var splitItems = itemsStr
          .split(RegExp(r'[,;]|\s+и\s+|\s+а также\s+', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      if (splitItems.length >= 2) {
        final lastItem = splitItems.last;
        final locMatch = RegExp(r'^(.+?)\s+(в|на|из|у|возле|около)\s+(.+)$', caseSensitive: false).firstMatch(lastItem);
        String? trailingLocation;
        if (locMatch != null) {
          splitItems[splitItems.length - 1] = locMatch.group(1)!.trim();
          trailingLocation = '${locMatch.group(2)} ${locMatch.group(3)}'.trim();
        }

        for (final item in splitItems) {
          final cleanItem = _capitalize(item.replaceAll(RegExp(r'^[•\-\d.\s]+'), '').trim());
          if (cleanItem.isNotEmpty) {
            subtasks.add(cleanItem);
          }
        }

        var baseText = working.substring(0, match.start + match.group(1)!.length).trim();
        if (trailingLocation != null) {
          baseText = '$baseText $trailingLocation';
        }
        return (subtasks, _cleanSpaces(baseText));
      }
    }

    // 2. Chained secondary action:
    // e.g. "мне в шарагу и успеть похавать до этого", "тренировка в зале и не забыть шейкер"
    final chainedActionPattern = RegExp(
      r'[,;]?\s+(?:и\s+)?(?:успеть\s+|перед\s+этим\s+|до\s+этого\s+|не\s+забыть\s+(?:бы\s+)?|заодно\s+|по\s+дороге\s+)(.+)$',
      caseSensitive: false,
    );
    final chainedMatch = chainedActionPattern.firstMatch(working);
    if (chainedMatch != null) {
      final actionText = chainedMatch.group(1)!.trim();
      if (actionText.isNotEmpty) {
        subtasks.add(_capitalize(actionText));
        final base = working.substring(0, chainedMatch.start).trim();
        return (subtasks, _cleanSpaces(base));
      }
    }

    // Also check patterns ending in "до этого" or "перед этим":
    // e.g. "и похавать до этого"
    final endingActionPattern = RegExp(
      r'[,;]?\s+(?:и\s+)(.+?)\s+(?:до\s+этого|перед\s+этим)$',
      caseSensitive: false,
    );
    final endingMatch = endingActionPattern.firstMatch(working);
    if (endingMatch != null) {
      final actionText = endingMatch.group(1)!.trim();
      if (actionText.isNotEmpty) {
        subtasks.add('${_capitalize(actionText)} до этого');
        final base = working.substring(0, endingMatch.start).trim();
        return (subtasks, _cleanSpaces(base));
      }
    }

    // 3. Inline triggers without colon: e.g. "взять форму и шейкер"
    final inlineTrigger = RegExp(
      r'(?:(?<=^|[^a-zA-Z0-9а-яА-ЯёЁ_]))(взять|не\s+забыть|купить)\s+([a-zA-Zа-яА-ЯёЁ0-9\s,;]+(?:,|(?:\s+и\s+))[a-zA-Zа-яА-ЯёЁ0-9\s,;]+)',
      caseSensitive: false,
    ).firstMatch(working);

    if (inlineTrigger != null) {
      final itemsStr = inlineTrigger.group(2)!.trim();
      final splitItems = itemsStr
          .split(RegExp(r'[,;]|\s+и\s+|\s+а также\s+', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length >= 2)
          .toList();

      if (splitItems.length >= 2) {
        for (final item in splitItems) {
          subtasks.add(_capitalize(item));
        }
        working = working.replaceFirst(inlineTrigger.group(0)!, ' ');
        return (subtasks, _cleanSpaces(working));
      }
    }

    return (subtasks, _cleanSpaces(working));
  }

  String? _extractCategory(String text, List<String> availableCategories) {
    final lower = text.toLowerCase();

    // Check available user categories first
    for (final cat in availableCategories) {
      if (cat == 'Все' || cat == 'Общее') continue;
      if (lower.contains(cat.toLowerCase())) {
        return cat;
      }
    }

    const ru = r'[а-яА-ЯёЁ]*';

    // Keyword mapping with Unicode-aware word boundaries and rich colloquial vocabulary
    if (_wordRegExp('универ$ru|шараг$ru|колледж$ru|техникум$ru|инстик$ru|институт$ru|пар[ыаеи]|парам$ru|лекци$ru|семинар$ru|лаб[ыаеи]$ru|лабораторн$ru|экзамен$ru|зачет$ru|сесси$ru|дз|домашк$ru|учеб$ru|книг$ru|стать$ru|курс$ru|урок$ru|курсач$ru|диплом$ru|препод$ru|школ$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Учеба', 'Study');
    }
    if (_wordRegExp('спорт$ru|тренировк$ru|треня$ru|трен[юе]$ru|зал$ru|качалк$ru|бег$ru|бассейн$ru|фитнес$ru|жим|разминк$ru|турник$ru|шейкер$ru|воркаут$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Спорт', 'Sport');
    }
    if (_wordRegExp('купить|покупк$ru|магазин$ru|магаз$ru|продукт$ru|шоппинг|заказать|доставк$ru|рынок|супермаркет$ru|похавать|поесть|перекусить|еда|хавчик$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Покупки', 'Shopping');
    }
    if (_wordRegExp('врач$ru|стоматолог$ru|доктор$ru|аптек$ru|таблетк$ru|анализ$ru|больниц$ru|клиник$ru|здоровь$ru|осмотр$ru|лекарств$ru|поликлиник$ru|зуб$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Здоровье', 'Health');
    }
    if (_wordRegExp('работ$ru|отчет$ru|митинг$ru|созвон$ru|клиент$ru|проект$ru|руководств$ru|начальник$ru|дедлайн$ru|договор$ru|офис$ru|смен[аеы]|таск$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Работа', 'Work');
    }
    if (_wordRegExp('уборк$ru|убраться|постирать|помыть|ремонт$ru|дом$ru|квартир$ru|хат[аеы]$ru|сантехник$ru|посуд$ru|мусор$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Дом', 'Home');
    }
    if (_wordRegExp('тусовк$ru|туса|вписк$ru|бар|паб|кафе$ru|рестик$ru|гулять|прогулк$ru|пацан$ru|друзь$ru|парикмахер$ru|барбер$ru').hasMatch(lower)) {
      return _findBestMatch(availableCategories, 'Личное', 'Personal');
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

  (String, String) _cleanTitleAndDescription(
    String cleanedText,
    String originalText,
  ) {
    var title = _normalizeConversationalTaskName(cleanedText);

    // If title was stripped too much, recover sensible snippet
    if (title.length < 3) {
      title = _capitalize(originalText.trim());
    }

    // If title is long (over 60 chars), break first sentence into title and rest into description
    var description = '';
    if (title.length > 60) {
      final sentences = title.split(RegExp(r'[.!?]\s+'));
      if (sentences.length > 1) {
        title = sentences.first.trim();
        description = sentences.sublist(1).join('. ').trim();
      }
    }

    return (title, description);
  }

  String _normalizeConversationalTaskName(String raw) {
    var text = _cleanSpaces(raw);

    // 1. "мне в/на/к [X]" or "надо в/на/к [X]" or "нужно в/на/к [X]" or "пора в/на/к [X]" -> "Пойти в/на/к [X]"
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
      // Bare "в/на/к [X]" -> "Пойти в/на/к [X]"
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

    // 2. "мне надо/нужно [делать]" -> "[Делать]"
    text = text.replaceFirst(
      RegExp(r'^(?:мне\s+)?(?:надо|нужно|необходимо|хочу|пора|планирую|задача:?)\s+', caseSensitive: false),
      '',
    );

    // 3. "не забыть [делать]" -> "[Делать]"
    text = text.replaceFirst(
      RegExp(r'^не\s+забыть\s+(?:бы\s+)?', caseSensitive: false),
      '',
    );

    // 4. "сгонять в/на/к [X]" -> "Сходить в/на/к [X]"
    text = text.replaceFirstMapped(
      RegExp(r'^(?:сгонять|сбегать|заскочить)\s+(в|на|к)\s+', caseSensitive: false),
      (m) => 'Сходить ${m.group(1)} ',
    );

    // 5. "успеть [делать]" -> "[Делать]"
    text = text.replaceFirst(
      RegExp(r'^успеть\s+', caseSensitive: false),
      '',
    );

    // Clean trailing prepositions or punctuation
    text = text.replaceAll(RegExp(r'\s+(?:и|а|до|перед|к|в|на)\s*$', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[,;:\s]+$'), '');

    return _capitalize(text.trim());
  }

  String _cleanSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
