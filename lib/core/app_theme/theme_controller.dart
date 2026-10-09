import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_color_palette.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/app_theme/app_theme_mode.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _loadFromPrefs();
  }

  static const String prefModeKey = 'app_theme_mode';
  static const String prefPaletteKey = 'app_color_palette';
  static const String colorPaletteKey = prefPaletteKey;
  final SharedPreferences _prefs;

  AppThemeMode _mode = AppThemeMode.dark;
  AppColorPalette _palette = AppColorPalette.iris;
  Brightness _systemBrightness = Brightness.dark;

  AppThemeMode get mode => _mode;
  AppColorPalette get palette => _palette;
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

  ThemeMode get themeMode => materialThemeMode;

  Future<void> toggleMidnight(bool enabled) async {
    await setThemeMode(enabled ? AppThemeMode.midnight : AppThemeMode.dark);
  }

  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      _syncAppColors();
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    _syncAppColors();
    await _prefs.setString(prefModeKey, newMode.key);
    notifyListeners();
  }

  Future<void> setPalette(AppColorPalette newPalette) async {
    if (_palette == newPalette) return;
    _palette = newPalette;
    _syncAppColors();
    await _prefs.setString(prefPaletteKey, newPalette.key);
    notifyListeners();
  }

  void _syncAppColors() {
    AppColors.update(
      isDark: isDark,
      isMidnight: isMidnight,
      palette: _palette,
    );
  }

  void _loadFromPrefs() {
    final savedModeKey = _prefs.getString(prefModeKey);
    _mode = AppThemeMode.fromKey(savedModeKey);

    final savedPaletteKey = _prefs.getString(prefPaletteKey);
    _palette = AppColorPalette.fromKey(savedPaletteKey);

    _syncAppColors();
  }
}
