import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_theme_mode.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _loadFromPrefs();
  }

  static const String _prefKey = 'app_theme_mode';
  final SharedPreferences _prefs;

  AppThemeMode _mode = AppThemeMode.dark;
  Brightness _systemBrightness = Brightness.dark;

  AppThemeMode get mode => _mode;
  Brightness get systemBrightness => _systemBrightness;

  bool get isMidnight => _mode == AppThemeMode.midnight;

  bool get isDark {
    switch (_mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
      case AppThemeMode.midnight:
        return true;
      case AppThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  ThemeMode get materialThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.midnight:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    await _prefs.setString(_prefKey, newMode.key);
    notifyListeners();
  }

  void _loadFromPrefs() {
    final savedKey = _prefs.getString(_prefKey);
    _mode = AppThemeMode.fromKey(savedKey);
  }
}
