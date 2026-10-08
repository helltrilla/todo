import 'package:flutter/material.dart';

/// Supported languages in TodoApp.
enum AppLanguage {
  ru('ru', 'Русский', 'Russian', '🇷🇺', Locale('ru')),
  en('en', 'English', 'English', '🇬🇧', Locale('en')),
  de('de', 'Deutsch', 'German', '🇩🇪', Locale('de')),
  fr('fr', 'Français', 'French', '🇫🇷', Locale('fr')),
  sr('sr', 'Српски', 'Serbian', '🇷🇸', Locale('sr'));

  const AppLanguage(
    this.code,
    this.nativeName,
    this.englishName,
    this.flag,
    this.locale,
  );

  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
  final Locale locale;

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((l) => l.locale).toList();

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.ru,
    );
  }
}
