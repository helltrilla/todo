import 'package:go_router/go_router.dart';
import 'package:todo/core/app_router/app_router_names.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/auth/presentation/screens/email_otp_screen.dart';
import 'package:todo/features/auth/presentation/screens/internal_auth_screen.dart';
import 'package:todo/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:todo/features/auth/presentation/screens/settings_screen.dart';
import 'package:todo/features/auth/presentation/screens/welcome_screen.dart';
import 'package:todo/features/tasks/presentation/screens/home_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: authController,
      redirect: (context, state) {
        final isLoggedIn = authController.isAuthenticated;
        final hasSeenOnboarding = authController.hasSeenOnboarding;
        final path = state.uri.path;
        final isOnboardingRoute = path == '/onboarding';
        final isAuthRoute =
            path == '/welcome' ||
            path == '/email-auth' ||
            path == '/internal-auth';

        if (!isLoggedIn && !hasSeenOnboarding) {
          return isOnboardingRoute ? null : '/onboarding';
        }
        if (hasSeenOnboarding && isOnboardingRoute) {
          return isLoggedIn ? '/home' : '/welcome';
        }
        if (!isLoggedIn && !isAuthRoute) {
          return '/welcome';
        }
        if (isLoggedIn && isAuthRoute) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          name: AppRouterNames.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/welcome',
          name: AppRouterNames.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/email-auth',
          name: AppRouterNames.emailAuth,
          builder: (context, state) => const EmailOtpScreen(),
        ),
        GoRoute(
          path: '/internal-auth',
          name: AppRouterNames.internalAuth,
          builder: (context, state) => const InternalAuthScreen(),
        ),
        GoRoute(
          path: '/home',
          name: AppRouterNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: AppRouterNames.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}
