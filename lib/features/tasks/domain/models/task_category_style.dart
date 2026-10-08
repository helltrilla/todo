import 'dart:convert';

import 'package:flutter/material.dart';

/// Immutable domain model for a customized Listodo category with an icon and color.
class TaskCategoryStyle {
  const TaskCategoryStyle({
    required this.name,
    required this.iconIndex,
    required this.colorIndex,
  });

  final String name;
  final int iconIndex;
  final int colorIndex;

  /// Curated preset icons matching the Listodo UI Kit.
  static const List<IconData> presetIcons = [
    Icons.work_outline_rounded, // 0: Work
    Icons.person_outline_rounded, // 1: Personal
    Icons.school_outlined, // 2: University / Study
    Icons.fitness_center_rounded, // 3: Sport / Fitness
    Icons.shopping_bag_outlined, // 4: Grocery / Shopping
    Icons.palette_outlined, // 5: Design / Creative
    Icons.home_outlined, // 6: Home
    Icons.favorite_border_rounded, // 7: Health
    Icons.movie_outlined, // 8: Entertainment
    Icons.savings_outlined, // 9: Finance
    Icons.code_rounded, // 10: Dev / Tech
    Icons.flight_takeoff_rounded, // 11: Travel
  ];

  /// Curated pastel/vibrant colors matching the Listodo Create Category palette.
  static const List<Color> presetColors = [
    Color(0xFF8875FF), // 0: Listodo Purple
    Color(0xFFF5C26B), // 1: Listodo Amber Yellow
    Color(0xFF66CC91), // 2: Mint Green
    Color(0xFF41CCA7), // 3: Teal
    Color(0xFF4181CC), // 4: Ocean Blue
    Color(0xFFFF8080), // 5: Coral Red
    Color(0xFFCC8441), // 6: Warm Orange
    Color(0xFF9741CC), // 7: Deep Violet
    Color(0xFFCC4173), // 8: Berry Pink
    Color(0xFF56CCF2), // 9: Sky Cyan
  ];

  IconData get icon => presetIcons[iconIndex.clamp(0, presetIcons.length - 1)];

  Color get color => presetColors[colorIndex.clamp(0, presetColors.length - 1)];

  /// Returns a sensible default style for built-in or legacy categories.
  factory TaskCategoryStyle.defaultFor(String name) {
    final lower = name.trim().toLowerCase();
    if (lower == 'work' || lower == 'работа') {
      return TaskCategoryStyle(name: name, iconIndex: 0, colorIndex: 5);
    }
    if (lower == 'personal' || lower == 'личное') {
      return TaskCategoryStyle(name: name, iconIndex: 1, colorIndex: 4);
    }
    if (lower == 'study' || lower == 'учеба' || lower == 'учёба') {
      return TaskCategoryStyle(name: name, iconIndex: 2, colorIndex: 0);
    }
    if (lower == 'sport' || lower == 'fitness' || lower == 'спорт') {
      return TaskCategoryStyle(name: name, iconIndex: 3, colorIndex: 2);
    }
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return TaskCategoryStyle(
      name: name,
      iconIndex: hash % presetIcons.length,
      colorIndex: hash % presetColors.length,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'iconIndex': iconIndex,
    'colorIndex': colorIndex,
  };

  factory TaskCategoryStyle.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] as String?) ?? 'Category';
    return TaskCategoryStyle(
      name: name,
      iconIndex: (map['iconIndex'] as int?) ?? 0,
      colorIndex: (map['colorIndex'] as int?) ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskCategoryStyle.fromJson(String source) =>
      TaskCategoryStyle.fromMap(json.decode(source) as Map<String, dynamic>);
}
