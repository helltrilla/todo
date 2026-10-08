import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_router/app_router.dart';
import 'package:todo/core/app_theme/app_theme.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences once at startup — the instance is then
  // injected into repositories so no async calls happen at read/write time.
  final prefs = await SharedPreferences.getInstance();

  runApp(MainApp(prefs: prefs));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthController _authController;
  late final TaskController _taskController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthRepositoryImpl(widget.prefs));
    _taskController = TaskController(TaskLocalRepository(widget.prefs));
    _router = AppRouter.createRouter(_authController);
  }

  @override
  void dispose() {
    _router.dispose();
    _taskController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<TaskController>.value(value: _taskController),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
