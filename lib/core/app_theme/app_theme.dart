import 'package:flutter/material.dart';
import 'package:todo/core/app_theme/app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.bgmain,
    primaryColor: AppColors.bg,
    appBarTheme: AppBarTheme(backgroundColor: AppColors.bgmain),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.bg),
    datePickerTheme: const DatePickerThemeData(),
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 30,
        fontStyle: FontStyle.italic,
        color: AppColors.maintext,
      ),
    ),
  );
}
