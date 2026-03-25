import 'package:go_router/go_router.dart';
import 'package:todo/layers/view/screens/home_screen.dart';

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: '/home',
    routes: [
      // можно и без этого было просто GoRoute и все
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return navigationShell;
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                // тут AppRouterNames.home
                name: 'home',

                // всегда используй const если возможно
                builder: (context, state) => const HomeScreen(),
                routes: [],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
