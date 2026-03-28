import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:todo/core/app_theme/app_colors.dart';
class AppTheme {
  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.bgmain,
    primaryColor: AppColors.bg,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.bg
    ),
  );
}

