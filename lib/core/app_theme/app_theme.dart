import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:todo/core/app_theme/app_colors.dart';
class AppTheme {
  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: AppColors.main,
    primaryColor: AppColors.bg,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.bg
    ),
  );
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
