import 'package:flutter/material.dart';

/// Available curated accent color palettes for the app.
/// Allows personalizing primary and secondary accent highlights.
enum AppColorPalette {
  iris(
    key: 'iris',
    labelRu: 'Ирис',
    labelEn: 'Iris',
    primary: Color(0xFF8875FF),
    accent: Color(0xFFF5C26B),
  ),
  ocean(
    key: 'ocean',
    labelRu: 'Океан',
    labelEn: 'Ocean',
    primary: Color(0xFF2563EB),
    accent: Color(0xFF38BDF8),
  ),
  emerald(
    key: 'emerald',
    labelRu: 'Изумруд',
    labelEn: 'Emerald',
    primary: Color(0xFF10B981),
    accent: Color(0xFFFBBF24),
  ),
  sunset(
    key: 'sunset',
    labelRu: 'Закат',
    labelEn: 'Sunset',
    primary: Color(0xFFF97316),
    accent: Color(0xFFFBBF24),
  ),
  amber(
    key: 'amber',
    labelRu: 'Янтарь',
    labelEn: 'Amber',
    primary: Color(0xFFF59E0B),
    accent: Color(0xFFFB7185),
  ),
  rose(
    key: 'rose',
    labelRu: 'Роза',
    labelEn: 'Rose',
    primary: Color(0xFFEC4899),
    accent: Color(0xFFA855F7),
  ),
  indigo(
    key: 'indigo',
    labelRu: 'Индиго',
    labelEn: 'Indigo',
    primary: Color(0xFF6366F1),
    accent: Color(0xFFEC4899),
  );

  const AppColorPalette({
    required this.key,
    required this.labelRu,
    required this.labelEn,
    required this.primary,
    required this.accent,
  });

  final String key;
  final String labelRu;
  final String labelEn;
  final Color primary;
  final Color accent;

  String get nameRu => labelRu;
  String get nameEn => labelEn;

  static AppColorPalette fromKey(String? key) {
    if (key == null) return AppColorPalette.iris;
    return AppColorPalette.values.firstWhere(
      (e) => e.key == key,
      orElse: () => AppColorPalette.iris,
    );
  }

  String localizedName(String languageCode) {
    return languageCode == 'ru' ? labelRu : labelEn;
  }
}
