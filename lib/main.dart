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
import 'package:todo/features/ambient/data/datasources/ambient_audio_native_data_source.dart';
import 'package:todo/features/ambient/data/repositories/ambient_audio_repository_impl.dart';
import 'package:todo/features/ambient/domain/usecases/get_ambient_presets_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/pause_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/play_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/set_ambient_volume_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/stop_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/presentation/controllers/ambient_audio_controller.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/backup/data/datasources/backup_native_data_source.dart';
import 'package:todo/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:todo/features/backup/domain/usecases/export_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/import_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/share_backup_use_case.dart';
import 'package:todo/features/backup/presentation/controllers/backup_controller.dart';
import 'package:todo/features/productivity/data/repositories/productivity_repository_impl.dart';
import 'package:todo/features/productivity/domain/usecases/calculate_productivity_dashboard_use_case.dart';
import 'package:todo/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/data/repositories/task_sync_repository.dart';
import 'package:todo/features/tasks/data/services/smart_task_parser_impl.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/voice/data/datasources/speech_to_text_datasource.dart';
import 'package:todo/features/voice/data/repositories/speech_recognition_repository_impl.dart';
import 'package:todo/features/voice/domain/usecases/initialize_speech_use_case.dart';
import 'package:todo/features/voice/domain/usecases/process_voice_task_use_case.dart';
import 'package:todo/features/voice/domain/usecases/start_listening_use_case.dart';
import 'package:todo/features/voice/domain/usecases/stop_listening_use_case.dart';
import 'package:todo/features/voice/presentation/controllers/voice_task_controller.dart';

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
  late final ISmartTaskParser _smartTaskParser;
  late final VoiceTaskController _voiceTaskController;
  late final AmbientAudioController _ambientAudioController;
  late final ProductivityController _productivityController;
  late final BackupController _backupController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeController = ThemeController(widget.prefs);
    _localeController = LocaleController(widget.prefs);
    _smartTaskParser = SmartTaskParserImpl(prefs: widget.prefs);
    final authRepo = AuthRepositoryImpl(widget.prefs);
    final localRepo = TaskLocalRepository(widget.prefs);
    final remoteDataSource = SupabaseTaskRemoteDataSource();
    final taskRepo = TaskSyncRepository(
      local: localRepo,
      remote: remoteDataSource,
      auth: authRepo,
    );

    // Voice recognition clean architecture wiring:
    final speechDataSource = SpeechToTextDataSource();
    final speechRepo = SpeechRecognitionRepositoryImpl(
      dataSource: speechDataSource,
    );
    _voiceTaskController = VoiceTaskController(
      initializeUseCase: InitializeSpeechUseCase(speechRepo),
      startListeningUseCase: StartListeningUseCase(speechRepo),
      stopListeningUseCase: StopListeningUseCase(speechRepo),
      processVoiceTaskUseCase: ProcessVoiceTaskUseCase(
        nlpParser: _smartTaskParser,
      ),
    );

    // Ambient soundscapes clean architecture wiring:
    final ambientDataSource = AmbientAudioNativeDataSource();
    final ambientRepo = AmbientAudioRepositoryImpl(
      dataSource: ambientDataSource,
    );
    _ambientAudioController = AmbientAudioController(
      getPresetsUseCase: GetAmbientPresetsUseCase(ambientRepo),
      playUseCase: PlayAmbientSoundUseCase(ambientRepo),
      pauseUseCase: PauseAmbientSoundUseCase(ambientRepo),
      stopUseCase: StopAmbientSoundUseCase(ambientRepo),
      setVolumeUseCase: SetAmbientVolumeUseCase(ambientRepo),
      externalStateStream: ambientRepo.stateChanges,
    );

    // Productivity analytics clean architecture wiring:
    final productivityRepo = const ProductivityRepositoryImpl();
    _productivityController = ProductivityController(
      calculateDashboardUseCase: CalculateProductivityDashboardUseCase(
        productivityRepo,
      ),
    );

    // Backup & Export clean architecture wiring:
    final backupDataSource = const BackupNativeDataSource();
    final backupRepo = BackupRepositoryImpl(dataSource: backupDataSource);
    _backupController = BackupController(
      exportUseCase: ExportTasksUseCase(backupRepo),
      importUseCase: ImportTasksUseCase(backupRepo),
      shareUseCase: ShareBackupUseCase(backupRepo),
    );

    _authController = AuthController(authRepo);
    _taskController = TaskController(taskRepo);
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
    _backupController.dispose();
    _productivityController.dispose();
    _ambientAudioController.dispose();
    _voiceTaskController.dispose();
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
        ChangeNotifierProvider<VoiceTaskController>.value(
          value: _voiceTaskController,
        ),
        ChangeNotifierProvider<AmbientAudioController>.value(
          value: _ambientAudioController,
        ),
        ChangeNotifierProvider<ProductivityController>.value(
          value: _productivityController,
        ),
        ChangeNotifierProvider<BackupController>.value(
          value: _backupController,
        ),
        Provider<ISmartTaskParser>.value(value: _smartTaskParser),
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
            darkTheme: themeCtrl.isMidnight ? AppTheme.midnight : AppTheme.dark,
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
