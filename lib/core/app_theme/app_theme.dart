import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo/core/app_theme/app_color_palette.dart';
import 'package:todo/core/app_theme/app_colors.dart';

class AppTheme {
  static ThemeData light([AppColorPalette palette = AppColorPalette.iris]) {
    final colors = AppThemeColors.light(palette);
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.bgmain,
      primaryColor: colors.primary,
      cardColor: colors.cardBg,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.accent,
        surface: colors.cardBg,
        onSurface: colors.maintext,
        outline: colors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgmain,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.maintext),
        titleTextStyle: GoogleFonts.inter(
          color: colors.maintext,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      datePickerTheme: const DatePickerThemeData(),
      extensions: [colors],
      textTheme: baseTextTheme.copyWith(
        titleMedium: GoogleFonts.inter(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: colors.maintext,
        ),
        bodyLarge: GoogleFonts.inter(color: colors.maintext),
        bodyMedium: GoogleFonts.inter(color: colors.maintext),
        bodySmall: GoogleFonts.inter(color: colors.labeltext),
      ),
    );
  }

  static ThemeData dark([AppColorPalette palette = AppColorPalette.iris]) {
    final colors = AppThemeColors.dark(palette);
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.bgmain,
      primaryColor: colors.primary,
      cardColor: colors.cardBg,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.accent,
        surface: colors.cardBg,
        onSurface: colors.maintext,
        outline: colors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgmain,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.maintext),
        titleTextStyle: GoogleFonts.inter(
          color: colors.maintext,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      datePickerTheme: const DatePickerThemeData(),
      extensions: [colors],
      textTheme: baseTextTheme.copyWith(
        titleMedium: GoogleFonts.inter(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: colors.maintext,
        ),
        bodyLarge: GoogleFonts.inter(color: colors.maintext),
        bodyMedium: GoogleFonts.inter(color: colors.maintext),
        bodySmall: GoogleFonts.inter(color: colors.labeltext),
      ),
    );
  }

  static ThemeData midnight([AppColorPalette palette = AppColorPalette.iris]) {
    final colors = AppThemeColors.midnight(palette);
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.bgmain,
      primaryColor: colors.primary,
      cardColor: colors.cardBg,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        secondary: palette.accent,
        surface: colors.cardBg,
        onSurface: colors.maintext,
        outline: colors.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgmain,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.maintext),
        titleTextStyle: GoogleFonts.inter(
          color: colors.maintext,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      datePickerTheme: const DatePickerThemeData(),
      extensions: [colors],
      textTheme: baseTextTheme.copyWith(
        titleMedium: GoogleFonts.inter(
          fontSize: 30,
          fontStyle: FontStyle.italic,
          color: colors.maintext,
        ),
        bodyLarge: GoogleFonts.inter(color: colors.maintext),
        bodyMedium: GoogleFonts.inter(color: colors.maintext),
        bodySmall: GoogleFonts.inter(color: colors.labeltext),
      ),
    );
  }
}
