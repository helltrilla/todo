import 'package:flutter/material.dart';
import 'package:todo/core/app_router/app_router.dart';
import 'package:todo/layers/view/screens/home_screen.dart';
import 'package:go_router/go_router.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: AppRouter.router);
  }
}
