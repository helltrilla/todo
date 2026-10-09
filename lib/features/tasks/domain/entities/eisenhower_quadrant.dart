import 'package:flutter/material.dart';

/// The 4 classical quadrants of the Eisenhower Priority Matrix.
enum EisenhowerQuadrant {
  q1(
    id: 'q1',
    title: 'Срочно и Важно',
    actionLabel: 'Сделай сейчас (Do)',
    color: Color(0xFFFF4D4F),
    accentColor: Color(0xFF381416),
    icon: Icons.local_fire_department_rounded,
    isUrgent: true,
    isImportant: true,
  ),
  q2(
    id: 'q2',
    title: 'Не срочно, но Важно',
    actionLabel: 'Запланируй (Schedule)',
    color: Color(0xFFFFA940),
    accentColor: Color(0xFF38260F),
    icon: Icons.calendar_today_rounded,
    isUrgent: false,
    isImportant: true,
  ),
  q3(
    id: 'q3',
    title: 'Срочно, но Не важно',
    actionLabel: 'Делегируй (Delegate)',
    color: Color(0xFF8875FF),
    accentColor: Color(0xFF221A3B),
    icon: Icons.group_rounded,
    isUrgent: true,
    isImportant: false,
  ),
  q4(
    id: 'q4',
    title: 'Не срочно и Не важно',
    actionLabel: 'Отложи / Удали (Eliminate)',
    color: Color(0xFF52C41A),
    accentColor: Color(0xFF14290F),
    icon: Icons.hourglass_bottom_rounded,
    isUrgent: false,
    isImportant: false,
  );

  final String id;
  final String title;
  final String actionLabel;
  final Color color;
  final Color accentColor;
  final IconData icon;
  final bool isUrgent;
  final bool isImportant;

  const EisenhowerQuadrant({
    required this.id,
    required this.title,
    required this.actionLabel,
    required this.color,
    required this.accentColor,
    required this.icon,
    required this.isUrgent,
    required this.isImportant,
  });

  static EisenhowerQuadrant fromFlags({
    required bool urgent,
    required bool important,
  }) {
    if (urgent && important) return EisenhowerQuadrant.q1;
    if (!urgent && important) return EisenhowerQuadrant.q2;
    if (urgent && !important) return EisenhowerQuadrant.q3;
    return EisenhowerQuadrant.q4;
  }
}
