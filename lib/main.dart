import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_router/app_router.dart';
import 'package:todo/core/app_theme/app_theme.dart';
import 'package:todo/core/app_theme/theme_controller.dart';
import 'package:todo/core/localization/app_language.dart';
import 'package:todo/core/localization/locale_controller.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences once at startup — the instance is then
  // injected into repositories and controllers so no async calls happen at read time.
  final prefs = await SharedPreferences.getInstance();

  runApp(MainApp(prefs: prefs));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late final AuthController _authController;
  late final TaskController _taskController;
  late final ThemeController _themeController;
  late final LocaleController _localeController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeController = ThemeController(widget.prefs);
    _localeController = LocaleController(widget.prefs);
    _authController = AuthController(AuthRepositoryImpl(widget.prefs));
    _taskController = TaskController(TaskLocalRepository(widget.prefs));
    _router = AppRouter.createRouter(_authController);

    _themeController.updateSystemBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeController.updateSystemBrightness(brightness);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _taskController.dispose();
    _authController.dispose();
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<TaskController>.value(value: _taskController),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
        ChangeNotifierProvider<LocaleController>.value(
          value: _localeController,
        ),
      ],
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
            theme: AppTheme.light,
            darkTheme:
                themeCtrl.isMidnight ? AppTheme.midnight : AppTheme.dark,
            themeMode: themeCtrl.materialThemeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
