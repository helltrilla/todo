import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_color_palette.dart';

/// Semantic, theme-adaptive color tokens representing the application design system.
/// Also implements [ThemeExtension] for clean Material 3 integration.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.bg,
    required this.bgmain,
    required this.cardBg,
    required this.surface,
    required this.maintext,
    required this.labeltext,
    required this.active,
    required this.primary,
    required this.accentYellow,
    required this.unactive,
    required this.border,
    required this.cardBorder,
    required this.divider,
    required this.icons,
    required this.isDark,
  });

  final Color bg;
  final Color bgmain;
  final Color cardBg;
  final Color surface;
  final Color maintext;
  final Color labeltext;
  final Color active;
  final Color primary;
  final Color accentYellow;
  final Color unactive;
  final Color border;
  final Color cardBorder;
  final Color divider;
  final Color icons;
  final bool isDark;

  /// High-contrast, clean, iOS/Material-grade Light Theme palette.
  factory AppThemeColors.light(AppColorPalette palette) => AppThemeColors(
        bg: const Color(0xFFF1F3F6),
        bgmain: const Color(0xFFF6F8FA),
        cardBg: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        maintext: const Color(0xFF111827),
        labeltext: const Color(0xFF6B7280),
        active: palette.primary,
        primary: palette.primary,
        accentYellow: palette.accent,
        unactive: const Color(0xFFE5E7EB),
        border: const Color(0xFFE5E7EB),
        cardBorder: const Color(0xFFE5E7EB),
        divider: const Color(0xFFF3F4F6),
        icons: const Color(0xFF374151),
        isDark: false,
      );

  /// Modern Slate/Charcoal Dark Theme palette.
  factory AppThemeColors.dark(AppColorPalette palette) => AppThemeColors(
        bg: const Color(0xFF242428),
        bgmain: const Color(0xFF121214),
        cardBg: const Color(0xFF1E1E22),
        surface: const Color(0xFF1E1E22),
        maintext: const Color(0xFFF9FAFB),
        labeltext: const Color(0xFF9CA3AF),
        active: palette.primary,
        primary: palette.primary,
        accentYellow: palette.accent,
        unactive: const Color(0xFF2C2D35),
        border: const Color(0x33FFFFFF),
        cardBorder: const Color(0x22FFFFFF),
        divider: const Color(0x1FFFFFFF),
        icons: const Color(0xFFF3F4F6),
        isDark: true,
      );

  /// True AMOLED Black Midnight Theme palette.
  factory AppThemeColors.midnight(AppColorPalette palette) => AppThemeColors(
        bg: const Color(0xFF101014),
        bgmain: const Color(0xFF000000),
        cardBg: const Color(0xFF0D0D10),
        surface: const Color(0xFF0D0D10),
        maintext: const Color(0xFFFFFFFF),
        labeltext: const Color(0xFF9E9E9E),
        active: palette.primary,
        primary: palette.primary,
        accentYellow: palette.accent,
        unactive: const Color(0xFF1A1A1E),
        border: const Color(0x2EFFFFFF),
        cardBorder: const Color(0x1FFFFFFF),
        divider: const Color(0x14FFFFFF),
        icons: const Color(0xFFFFFFFF),
        isDark: true,
      );

  @override
  AppThemeColors copyWith({
    Color? bg,
    Color? bgmain,
    Color? cardBg,
    Color? surface,
    Color? maintext,
    Color? labeltext,
    Color? active,
    Color? primary,
    Color? accentYellow,
    Color? unactive,
    Color? border,
    Color? cardBorder,
    Color? divider,
    Color? icons,
    bool? isDark,
  }) {
    return AppThemeColors(
      bg: bg ?? this.bg,
      bgmain: bgmain ?? this.bgmain,
      cardBg: cardBg ?? this.cardBg,
      surface: surface ?? this.surface,
      maintext: maintext ?? this.maintext,
      labeltext: labeltext ?? this.labeltext,
      active: active ?? this.active,
      primary: primary ?? this.primary,
      accentYellow: accentYellow ?? this.accentYellow,
      unactive: unactive ?? this.unactive,
      border: border ?? this.border,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      icons: icons ?? this.icons,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      bgmain: Color.lerp(bgmain, other.bgmain, t) ?? bgmain,
      cardBg: Color.lerp(cardBg, other.cardBg, t) ?? cardBg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      maintext: Color.lerp(maintext, other.maintext, t) ?? maintext,
      labeltext: Color.lerp(labeltext, other.labeltext, t) ?? labeltext,
      active: Color.lerp(active, other.active, t) ?? active,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      accentYellow:
          Color.lerp(accentYellow, other.accentYellow, t) ?? accentYellow,
      unactive: Color.lerp(unactive, other.unactive, t) ?? unactive,
      border: Color.lerp(border, other.border, t) ?? border,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      icons: Color.lerp(icons, other.icons, t) ?? icons,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Central color registry providing dynamic getters that instantly resolve
/// to the current theme mode and color palette.
class AppColors {
  static AppThemeColors current = AppThemeColors.dark(AppColorPalette.iris);

  static Color get bg => current.bg;
  static Color get bgmain => current.bgmain;
  static Color get cardBg => current.cardBg;
  static Color get surface => current.surface;
  static Color get maintext => current.maintext;
  static Color get labeltext => current.labeltext;
  static Color get active => current.active;
  static Color get primary => current.primary;
  static Color get accentYellow => current.accentYellow;
  static Color get unactive => current.unactive;
  static Color get border => current.border;
  static Color get cardBorder => current.cardBorder;
  static Color get divider => current.divider;
  static Color get icons => current.icons;
  static bool get isDark => current.isDark;

  // Compile-time stable constants
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color legacyDarkGray = CupertinoColors.darkBackgroundGray;

  /// Updates active global colors directly with the provided theme extension.
  static void apply(AppThemeColors colors) {
    current = colors;
  }

  /// Updates active global colors to sync with the current theme & palette.
  static void update({
    required bool isDark,
    required bool isMidnight,
    required AppColorPalette palette,
  }) {
    if (isMidnight) {
      current = AppThemeColors.midnight(palette);
    } else if (isDark) {
      current = AppThemeColors.dark(palette);
    } else {
      current = AppThemeColors.light(palette);
    }
  }

  /// Convenience helper to obtain theme colors from [BuildContext].
  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ?? current;
  }
}
