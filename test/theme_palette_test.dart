import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/app_color_palette.dart';
import 'package:todo/core/app_theme/app_colors.dart';
import 'package:todo/core/app_theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColorPalette Enum Tests', () {
    test('contains all 7 curated color schemes', () {
      expect(AppColorPalette.values.length, 7);
      expect(AppColorPalette.values, contains(AppColorPalette.iris));
      expect(AppColorPalette.values, contains(AppColorPalette.ocean));
      expect(AppColorPalette.values, contains(AppColorPalette.emerald));
      expect(AppColorPalette.values, contains(AppColorPalette.sunset));
      expect(AppColorPalette.values, contains(AppColorPalette.amber));
      expect(AppColorPalette.values, contains(AppColorPalette.rose));
      expect(AppColorPalette.values, contains(AppColorPalette.indigo));
    });

    test('each palette has distinct colors and localized names', () {
      for (final palette in AppColorPalette.values) {
        expect(palette.nameRu.isNotEmpty, isTrue);
        expect(palette.nameEn.isNotEmpty, isTrue);
        expect(palette.labelRu.isNotEmpty, isTrue);
        expect(palette.labelEn.isNotEmpty, isTrue);
        expect(palette.localizedName('ru'), palette.labelRu);
        expect(palette.localizedName('en'), palette.labelEn);
        expect(palette.primary, isNotNull);
        expect(palette.accent, isNotNull);
      }
    });

    test('fromKey parses correctly and falls back to iris for unknown', () {
      expect(AppColorPalette.fromKey('ocean'), AppColorPalette.ocean);
      expect(AppColorPalette.fromKey('emerald'), AppColorPalette.emerald);
      expect(AppColorPalette.fromKey('sunset'), AppColorPalette.sunset);
      expect(AppColorPalette.fromKey('amber'), AppColorPalette.amber);
      expect(AppColorPalette.fromKey('rose'), AppColorPalette.rose);
      expect(AppColorPalette.fromKey('indigo'), AppColorPalette.indigo);
      expect(AppColorPalette.fromKey('unknown_key'), AppColorPalette.iris);
      expect(AppColorPalette.fromKey(null), AppColorPalette.iris);
    });
  });

  group('ThemeController & Palette Persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initializes with default iris palette and dark mode', () {
      final ctrl = ThemeController(prefs);
      expect(ctrl.palette, AppColorPalette.iris);
      expect(ctrl.themeMode, ThemeMode.dark);
    });

    test('loads saved palette from SharedPreferences', () async {
      await prefs.setString(ThemeController.colorPaletteKey, 'emerald');
      final ctrl = ThemeController(prefs);
      expect(ctrl.palette, AppColorPalette.emerald);
    });

    test('setPalette updates state, persists key and notifies listeners', () async {
      final ctrl = ThemeController(prefs);
      bool notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.setPalette(AppColorPalette.sunset);

      expect(ctrl.palette, AppColorPalette.sunset);
      expect(prefs.getString(ThemeController.colorPaletteKey), 'sunset');
      expect(notified, isTrue);
    });

    test('toggleMidnight switches between dark and midnight', () async {
      final ctrl = ThemeController(prefs);
      expect(ctrl.isMidnight, isFalse);

      await ctrl.toggleMidnight(true);
      expect(ctrl.isMidnight, isTrue);
      expect(prefs.getString(ThemeController.prefModeKey), 'midnight');

      await ctrl.toggleMidnight(false);
      expect(ctrl.isMidnight, isFalse);
      expect(prefs.getString(ThemeController.prefModeKey), 'dark');
    });
  });

  group('AppThemeColors & Dynamic Contrast Tests', () {
    test('Light theme provides high-contrast clean iOS/Material styling', () {
      final colors = AppThemeColors.light(AppColorPalette.iris);
      expect(colors.isDark, isFalse);
      expect(colors.maintext, const Color(0xFF111827));
      expect(colors.labeltext, const Color(0xFF6B7280));
      expect(colors.border, const Color(0xFFE5E7EB));
      expect(colors.cardBg, Colors.white);
      expect(colors.bgmain, const Color(0xFFF6F8FA));
    });

    test('Dark theme provides proper dark slate styling', () {
      final colors = AppThemeColors.dark(AppColorPalette.ocean);
      expect(colors.isDark, isTrue);
      expect(colors.maintext, const Color(0xFFF9FAFB));
      expect(colors.labeltext, const Color(0xFF9CA3AF));
      expect(colors.cardBg, const Color(0xFF1E1E22));
    });

    test('Midnight theme provides deep true black styling', () {
      final colors = AppThemeColors.midnight(AppColorPalette.emerald);
      expect(colors.isDark, isTrue);
      expect(colors.bgmain, const Color(0xFF000000));
      expect(colors.maintext, const Color(0xFFFFFFFF));
      expect(colors.cardBg, const Color(0xFF0D0D10));
    });

    test('AppColors.apply and update dynamically sync with palette and brightness', () {
      final lightExt = AppThemeColors.light(AppColorPalette.sunset);
      AppColors.apply(lightExt);

      expect(AppColors.primary, AppColorPalette.sunset.primary);
      expect(AppColors.maintext, const Color(0xFF111827));
      expect(AppColors.cardBg, Colors.white);

      final darkExt = AppThemeColors.dark(AppColorPalette.rose);
      AppColors.apply(darkExt);

      expect(AppColors.primary, AppColorPalette.rose.primary);
      expect(AppColors.maintext, const Color(0xFFF9FAFB));
      expect(AppColors.cardBg, const Color(0xFF1E1E22));

      AppColors.update(
        isDark: false,
        isMidnight: false,
        palette: AppColorPalette.amber,
      );

      expect(AppColors.primary, AppColorPalette.amber.primary);
      expect(AppColors.cardBg, Colors.white);
    });
  });

  group('Palette Selector Interactive Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders palette choices and allows switching active palette', (tester) async {
      final themeCtrl = ThemeController(prefs);

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: themeCtrl,
          builder: (context, _) {
            return MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: AppColorPalette.values.map((palette) {
                    return ListTile(
                      title: Text(palette.labelRu),
                      selected: themeCtrl.palette == palette,
                      onTap: () => themeCtrl.setPalette(palette),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify palettes are rendered
      expect(find.text('Ирис'), findsOneWidget);
      expect(find.text('Океан'), findsOneWidget);
      expect(find.text('Изумруд'), findsOneWidget);
      expect(find.text('Закат'), findsOneWidget);

      // Tap on Ocean palette
      await tester.tap(find.text('Океан'));
      await tester.pumpAndSettle();

      expect(themeCtrl.palette, AppColorPalette.ocean);
      expect(prefs.getString(ThemeController.colorPaletteKey), 'ocean');

      // Tap on Emerald palette
      await tester.tap(find.text('Изумруд'));
      await tester.pumpAndSettle();

      expect(themeCtrl.palette, AppColorPalette.emerald);
      expect(prefs.getString(ThemeController.colorPaletteKey), 'emerald');
    });
  });
}
