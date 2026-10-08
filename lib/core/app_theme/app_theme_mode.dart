import 'package:flutter/material.dart';

/// Supported application theme modes.
enum AppThemeMode {
  dark('dark', 'Тёмная', 'Dark', Icons.dark_mode_rounded),
  light('light', 'Светлая', 'Light', Icons.light_mode_rounded),
  midnight('midnight', 'Глубокий чёрный', 'Midnight', Icons.nightlight_round),
  system('system', 'Системная', 'System', Icons.settings_brightness_rounded);

  const AppThemeMode(
    this.key,
    this.labelRu,
    this.labelEn,
    this.icon,
  );

  final String key;
  final String labelRu;
  final String labelEn;
  final IconData icon;

  static AppThemeMode fromKey(String? key) {
    return AppThemeMode.values.firstWhere(
      (m) => m.key == key,
      orElse: () => AppThemeMode.dark,
    );
  }
}
