import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/localization/app_language.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    _loadFromPrefs();
  }

  static const String _prefKey = 'app_language_code';
  final SharedPreferences _prefs;

  AppLanguage _currentLanguage = AppLanguage.ru;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get locale => _currentLanguage.locale;

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    await _prefs.setString(_prefKey, language.code);
    notifyListeners();
  }

  void _loadFromPrefs() {
    final savedCode = _prefs.getString(_prefKey);
    _currentLanguage = AppLanguage.fromCode(savedCode);
  }
}
