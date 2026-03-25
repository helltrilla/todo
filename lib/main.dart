import 'package:flutter/material.dart';
import 'package:todo/core/app_router/app_router.dart';
import 'package:todo/core/app_theme/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // и так прокидываешь тему
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
