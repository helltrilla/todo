enum RecurrenceRule {
  none('none', 'Не повторять', 'Без повтора'),
  daily('daily', 'Каждый день', 'Ежедневно'),
  weekdays('weekdays', 'По будням (Пн–Пт)', 'По будням'),
  weekly('weekly', 'Каждую неделю', 'Еженедельно'),
  monthly('monthly', 'Каждый месяц', 'Ежемесячно');

  const RecurrenceRule(this.key, this.label, this.shortLabel);

  final String key;
  final String label;
  final String shortLabel;

  bool get isRepeating => this != RecurrenceRule.none;

  /// Computes the next occurrence [DateTime] strictly after [baseDate].
  DateTime nextDueDate(DateTime baseDate) {
    switch (this) {
      case RecurrenceRule.none:
        return baseDate;
      case RecurrenceRule.daily:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 1,
          baseDate.hour,
          baseDate.minute,
        );
      case RecurrenceRule.weekdays:
        var next = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 1,
          baseDate.hour,
          baseDate.minute,
        );
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = DateTime(
            next.year,
            next.month,
            next.day + 1,
            next.hour,
            next.minute,
          );
        }
        return next;
      case RecurrenceRule.weekly:
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day + 7,
          baseDate.hour,
          baseDate.minute,
        );
      case RecurrenceRule.monthly:
        final nextMonthYear =
            baseDate.month == 12 ? baseDate.year + 1 : baseDate.year;
        final nextMonth = baseDate.month == 12 ? 1 : baseDate.month + 1;
        // In pure Dart, DateTime(y, m + 1, 0).day returns total days in month `m`.
        final maxDays = DateTime(nextMonthYear, nextMonth + 1, 0).day;
        final clampedDay = baseDate.day > maxDays ? maxDays : baseDate.day;
        return DateTime(
          nextMonthYear,
          nextMonth,
          clampedDay,
          baseDate.hour,
          baseDate.minute,
        );
    }
  }

  static RecurrenceRule fromKey(String? raw) {
    if (raw == null || raw.isEmpty) return RecurrenceRule.none;
    for (final rule in RecurrenceRule.values) {
      if (rule.key == raw) return rule;
    }
    return RecurrenceRule.none;
  }
}
