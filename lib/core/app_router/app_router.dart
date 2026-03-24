import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo/layers/view/screens/home_screen.dart';
class AppRouter {
static GoRouter get router => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return navigationShell;
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => HomeScreen(),
              routes: []
            ),
          ],
        ),
      ],
    ),
  ],
);
}