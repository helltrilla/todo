import 'package:flutter/material.dart';

/// Four expressive task priority levels with distinct icons, colors, and descriptions.
enum PriorityLevel {
  p1(
    'Срочно',
    'Горит — сделать в первую очередь',
    Color(0xFFFF4D4F),
    Icons.local_fire_department_rounded,
  ),
  p2(
    'Высокий',
    'Важная задача с высоким фокусом',
    Color(0xFFFFA940),
    Icons.bolt_rounded,
  ),
  p3('Средний', 'Обычный приоритет', Color(0xFF8875FF), Icons.flag_rounded),
  p4(
    'Низкий',
    'Можно сделать в свободное время',
    Color(0xFF2ECC71),
    Icons.eco_rounded,
  ),
  none(
    'Без приоритета',
    'Стандартная задача',
    Color(0xFF6E6E6E),
    Icons.outlined_flag_rounded,
  );

  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;

  const PriorityLevel(this.label, this.subtitle, this.color, this.icon);

  /// Selectable levels shown in the picker dialog (excludes [none]).
  static const List<PriorityLevel> selectable = [p1, p2, p3, p4];

  /// Safely resolves a [PriorityLevel] from a stored index.
  /// Maps legacy indices (4..9) to [p4] and -1 to [none].
  static PriorityLevel fromIndex(int index) {
    if (index < 0) return PriorityLevel.none;
    if (index == 0) return PriorityLevel.p1;
    if (index == 1) return PriorityLevel.p2;
    if (index == 2) return PriorityLevel.p3;
    return PriorityLevel.p4;
  }
}
