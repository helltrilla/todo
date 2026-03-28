import 'package:go_router/go_router.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/layers/view/screens/home_screen.dart';

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        name: AppRouterNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
