import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_router/app_router.dart';
import 'package:todo/core/app_theme/app_theme.dart';
import 'package:todo/core/app_theme/theme_controller.dart';
import 'package:todo/core/di/injection_container.dart';
import 'package:todo/core/localization/app_language.dart';
import 'package:todo/core/localization/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize clean dependency injection container once at startup
  final dependencies = await setupDependencies();

  runApp(MainApp(dependencies: dependencies));
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    this.dependencies,
    this.prefs,
  }) : assert(
         dependencies != null || prefs != null,
         'Either dependencies or prefs must be provided',
       );

  final AppDependencies? dependencies;
  final SharedPreferences? prefs;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final AppDependencies _dependencies;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dependencies = widget.dependencies ?? AppDependencies.init(widget.prefs!);
    _router = AppRouter.createRouter(_dependencies.authController);

    _dependencies.themeController.updateSystemBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dependencies.widgetSyncController.processPendingToggles(
        onToggle: _dependencies.taskController.toggleCompleted,
      );
      _dependencies.mediaPlaybackService.onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _dependencies.mediaPlaybackService.onAppPaused();
    }
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _dependencies.themeController.updateSystemBrightness(brightness);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _dependencies.providers,
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themeCtrl, localeCtrl, _) {
          return MaterialApp.router(
            title: 'TodoApp',
            locale: localeCtrl.locale,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(themeCtrl.palette),
            darkTheme: themeCtrl.isMidnight
                ? AppTheme.midnight(themeCtrl.palette)
                : AppTheme.dark(themeCtrl.palette),
            themeMode: themeCtrl.materialThemeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 768) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return ColoredBox(
                      color: isDark
                          ? const Color(0xFF0D0D10)
                          : const Color(0xFFE2E4E9),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.45 : 0.08,
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRect(child: child),
                          ),
                        ),
                      ),
                    );
                  }
                  return child;
                },
              );
            },
          );
        },
      ),
    );
  }
}
