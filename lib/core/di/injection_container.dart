import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/app_theme/theme_controller.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/localization/locale_controller.dart';
import 'package:todo/core/notifications/media_playback_service.dart';
import 'package:todo/core/notifications/notification_service.dart';
import 'package:todo/features/ambient/data/datasources/ambient_audio_native_data_source.dart';
import 'package:todo/features/ambient/data/repositories/ambient_audio_repository_impl.dart';
import 'package:todo/features/ambient/domain/usecases/get_ambient_presets_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/pause_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/play_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/set_ambient_volume_use_case.dart';
import 'package:todo/features/ambient/domain/usecases/stop_ambient_sound_use_case.dart';
import 'package:todo/features/ambient/presentation/controllers/ambient_audio_controller.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todo/features/backup/data/datasources/backup_native_data_source.dart';
import 'package:todo/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:todo/features/backup/domain/usecases/export_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/import_tasks_use_case.dart';
import 'package:todo/features/backup/domain/usecases/share_backup_use_case.dart';
import 'package:todo/features/backup/presentation/controllers/backup_controller.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_local_data_source.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_remote_data_source.dart';
import 'package:todo/features/digest/data/repositories/daily_digest_repository_impl.dart';
import 'package:todo/features/digest/domain/usecases/daily_digest_use_case.dart';
import 'package:todo/features/digest/presentation/controllers/daily_digest_controller.dart';
import 'package:todo/features/productivity/data/repositories/productivity_repository_impl.dart';
import 'package:todo/features/productivity/domain/usecases/calculate_productivity_dashboard_use_case.dart';
import 'package:todo/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:todo/features/tasks/data/datasources/playlist_metadata_remote_data_source.dart';
import 'package:todo/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:todo/features/tasks/data/repositories/sync_repository_impl.dart';
import 'package:todo/features/tasks/data/repositories/task_local_repository.dart';
import 'package:todo/features/tasks/data/repositories/task_sync_repository.dart';
import 'package:todo/features/tasks/data/services/smart_task_parser_impl.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
import 'package:todo/features/tasks/domain/usecases/get_playlist_metadata_use_case.dart';
import 'package:todo/features/tasks/domain/usecases/sync_tasks_use_case.dart';
import 'package:todo/features/tasks/presentation/controllers/focus_playlist_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/pomodoro_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/sync_controller.dart';
import 'package:todo/features/tasks/presentation/controllers/task_controller.dart';
import 'package:todo/features/voice/data/datasources/speech_to_text_datasource.dart';
import 'package:todo/features/voice/data/repositories/speech_recognition_repository_impl.dart';
import 'package:todo/features/voice/domain/usecases/initialize_speech_use_case.dart';
import 'package:todo/features/voice/domain/usecases/process_voice_task_use_case.dart';
import 'package:todo/features/voice/domain/usecases/start_listening_use_case.dart';
import 'package:todo/features/voice/domain/usecases/stop_listening_use_case.dart';
import 'package:todo/features/voice/presentation/controllers/voice_task_controller.dart';
import 'package:todo/features/widgets/data/datasources/widget_native_data_source.dart';
import 'package:todo/features/widgets/data/repositories/widget_sync_repository_impl.dart';
import 'package:todo/features/widgets/domain/entities/widget_pomodoro_state.dart';
import 'package:todo/features/widgets/domain/usecases/process_widget_toggles_use_case.dart';
import 'package:todo/features/widgets/domain/usecases/sync_widget_snapshot_use_case.dart';
import 'package:todo/features/widgets/presentation/controllers/widget_sync_controller.dart';

/// Strongly-typed Dependency Injection container holding configured feature modules,
/// repositories, use cases, and controllers.
class AppDependencies {
  final SharedPreferences prefs;
  final ThemeController themeController;
  final LocaleController localeController;
  final ISmartTaskParser smartTaskParser;
  final INotificationService notificationService;
  final AuthController authController;
  final TaskController taskController;
  final SyncController syncController;
  final PomodoroController pomodoroController;
  final FocusPlaylistController focusPlaylistController;
  final MediaPlaybackService mediaPlaybackService;
  final AmbientAudioController ambientAudioController;
  final VoiceTaskController voiceTaskController;
  final ProductivityController productivityController;
  final BackupController backupController;
  final WidgetSyncController widgetSyncController;
  final DailyDigestController dailyDigestController;

  const AppDependencies({
    required this.prefs,
    required this.themeController,
    required this.localeController,
    required this.smartTaskParser,
    required this.notificationService,
    required this.authController,
    required this.taskController,
    required this.syncController,
    required this.pomodoroController,
    required this.focusPlaylistController,
    required this.mediaPlaybackService,
    required this.ambientAudioController,
    required this.voiceTaskController,
    required this.productivityController,
    required this.backupController,
    required this.widgetSyncController,
    required this.dailyDigestController,
  });

  /// Exposes providers for [MultiProvider] in the root widget tree.
  List<SingleChildWidget> get providers => [
    Provider<INotificationService>.value(value: notificationService),
    ChangeNotifierProvider<AuthController>.value(value: authController),
    ChangeNotifierProvider<TaskController>.value(value: taskController),
    ChangeNotifierProvider<DailyDigestController>.value(
      value: dailyDigestController,
    ),
    ChangeNotifierProvider<PomodoroController>.value(
      value: pomodoroController,
    ),
    ChangeNotifierProvider<SyncController>.value(value: syncController),
    ChangeNotifierProvider<ThemeController>.value(value: themeController),
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
    ChangeNotifierProvider<VoiceTaskController>.value(
      value: voiceTaskController,
    ),
    ChangeNotifierProvider<AmbientAudioController>.value(
      value: ambientAudioController,
    ),
    ChangeNotifierProvider<FocusPlaylistController>.value(
      value: focusPlaylistController,
    ),
    ChangeNotifierProvider<MediaPlaybackService>.value(
      value: mediaPlaybackService,
    ),
    ChangeNotifierProvider<ProductivityController>.value(
      value: productivityController,
    ),
    ChangeNotifierProvider<BackupController>.value(value: backupController),
    ChangeNotifierProvider<WidgetSyncController>.value(
      value: widgetSyncController,
    ),
    Provider<ISmartTaskParser>.value(value: smartTaskParser),
  ];

  /// Disposes all managed controllers and services upon application teardown.
  void dispose() {
    widgetSyncController.dispose();
    dailyDigestController.dispose();
    backupController.dispose();
    productivityController.dispose();
    ambientAudioController.dispose();
    mediaPlaybackService.dispose();
    focusPlaylistController.dispose();
    voiceTaskController.dispose();
    pomodoroController.dispose();
    syncController.dispose();
    taskController.dispose();
    authController.dispose();
    localeController.dispose();
    themeController.dispose();
  }

  /// Factory assembly splitting registrations across logical layers.
  static AppDependencies init(
    SharedPreferences prefs, {
    INotificationService? notificationService,
  }) {
    // 0. Configuration check
    AppConfig.validate();

    // 1. Core & Platform services
    final notifService = notificationService ?? NotificationServiceImpl();
    final (themeCtrl, localeCtrl, smartParser) = _initCore(prefs);

    // 2. Auth
    final (authRepo, authCtrl) = _initAuth(prefs);

    // 3. Tasks & Sync
    final (taskCtrl, syncCtrl) = _initTasks(prefs, authRepo, notifService);

    // 4. Interactive App Widgets
    final widgetSyncCtrl = _initWidgets(taskCtrl);

    // 5. Focus & Media Hub
    final (pomoCtrl, playlistCtrl, mediaService) = _initFocus(
      prefs,
      taskCtrl,
      widgetSyncCtrl,
      notifService,
    );

    // 6. Ambient Soundscapes
    final ambientAudioCtrl = _initAmbientAudio();

    // 7. Voice Recognition
    final voiceTaskCtrl = _initVoice(smartParser);

    // 8. Productivity Analytics
    final productivityCtrl = _initProductivity();

    // 9. Backup & Export
    final backupCtrl = _initBackup();

    // 10. AI Daily Digest
    final dailyDigestCtrl = _initDigest(prefs);

    return AppDependencies(
      prefs: prefs,
      themeController: themeCtrl,
      localeController: localeCtrl,
      smartTaskParser: smartParser,
      notificationService: notifService,
      authController: authCtrl,
      taskController: taskCtrl,
      syncController: syncCtrl,
      pomodoroController: pomoCtrl,
      focusPlaylistController: playlistCtrl,
      mediaPlaybackService: mediaService,
      ambientAudioController: ambientAudioCtrl,
      voiceTaskController: voiceTaskCtrl,
      productivityController: productivityCtrl,
      backupController: backupCtrl,
      widgetSyncController: widgetSyncCtrl,
      dailyDigestController: dailyDigestCtrl,
    );
  }

  static (ThemeController, LocaleController, ISmartTaskParser) _initCore(
    SharedPreferences prefs,
  ) {
    final themeCtrl = ThemeController(prefs);
    final localeCtrl = LocaleController(prefs);
    final smartParser = SmartTaskParserImpl(prefs: prefs);
    return (themeCtrl, localeCtrl, smartParser);
  }

  static (AuthRepositoryImpl, AuthController) _initAuth(
    SharedPreferences prefs,
  ) {
    final authRepo = AuthRepositoryImpl(prefs);
    final authCtrl = AuthController(authRepo);
    return (authRepo, authCtrl);
  }

  static (TaskController, SyncController) _initTasks(
    SharedPreferences prefs,
    AuthRepositoryImpl authRepo,
    INotificationService notifService,
  ) {
    final localRepo = TaskLocalRepository(prefs);
    final remoteDataSource = SupabaseTaskRemoteDataSource();
    final syncRepo = SyncRepositoryImpl(
      local: localRepo,
      remote: remoteDataSource,
      auth: authRepo,
    );
    final taskRepo = TaskSyncRepository.withSyncRepo(
      local: localRepo,
      syncRepository: syncRepo,
    );
    final syncTasksUseCase = SyncTasksUseCase(syncRepo);

    late final TaskController taskCtrl;
    final syncCtrl = SyncController(
      syncUseCase: syncTasksUseCase,
      onTasksSynced: (tasks) => taskCtrl.onTasksSynced(tasks),
    );
    taskCtrl = TaskController(
      taskRepo,
      syncController: syncCtrl,
      notificationService: notifService,
    );

    return (taskCtrl, syncCtrl);
  }

  static (PomodoroController, FocusPlaylistController, MediaPlaybackService)
  _initFocus(
    SharedPreferences prefs,
    TaskController taskCtrl,
    WidgetSyncController widgetSyncCtrl,
    INotificationService notifService,
  ) {
    final pomoCtrl = PomodoroController(
      prefs: prefs,
      notificationService: notifService,
      onSessionFinished: (taskId, minutes, taskName) async {
        if (taskId != null) {
          await taskCtrl.recordFocusSession(taskId, minutes: minutes);
        }
      },
      onStateChanged: (isRunning, remainingSec, totalSec) {
        widgetSyncCtrl.syncFromTasks(
          tasks: taskCtrl.tasks,
          pomodoro: WidgetPomodoroState(
            isRunning: isRunning,
            remainingSeconds: remainingSec,
            totalSeconds: totalSec,
            mode: 'focus',
            completedPomodoros: taskCtrl.tasks.fold<int>(
              0,
              (acc, t) => acc + t.pomodoroCount,
            ),
          ),
        );
      },
    );

    final playlistDataSource = PlaylistMetadataRemoteDataSource();
    final getPlaylistMetadataUseCase = GetPlaylistMetadataUseCase(
      playlistDataSource,
    );
    final playlistCtrl = FocusPlaylistController(
      prefs: prefs,
      getMetadataUseCase: getPlaylistMetadataUseCase,
    );

    final mediaService = MediaPlaybackService(
      notificationService: notifService,
    );

    return (pomoCtrl, playlistCtrl, mediaService);
  }

  static AmbientAudioController _initAmbientAudio() {
    final ambientDataSource = AmbientAudioNativeDataSource();
    final ambientRepo = AmbientAudioRepositoryImpl(
      dataSource: ambientDataSource,
    );
    return AmbientAudioController(
      getPresetsUseCase: GetAmbientPresetsUseCase(ambientRepo),
      playUseCase: PlayAmbientSoundUseCase(ambientRepo),
      pauseUseCase: PauseAmbientSoundUseCase(ambientRepo),
      stopUseCase: StopAmbientSoundUseCase(ambientRepo),
      setVolumeUseCase: SetAmbientVolumeUseCase(ambientRepo),
      externalStateStream: ambientRepo.stateChanges,
    );
  }

  static VoiceTaskController _initVoice(ISmartTaskParser smartParser) {
    final speechDataSource = SpeechToTextDataSource();
    final speechRepo = SpeechRecognitionRepositoryImpl(
      dataSource: speechDataSource,
    );
    return VoiceTaskController(
      initializeUseCase: InitializeSpeechUseCase(speechRepo),
      startListeningUseCase: StartListeningUseCase(speechRepo),
      stopListeningUseCase: StopListeningUseCase(speechRepo),
      processVoiceTaskUseCase: ProcessVoiceTaskUseCase(nlpParser: smartParser),
    );
  }

  static ProductivityController _initProductivity() {
    const productivityRepo = ProductivityRepositoryImpl();
    return ProductivityController(
      calculateDashboardUseCase: CalculateProductivityDashboardUseCase(
        productivityRepo,
      ),
    );
  }

  static BackupController _initBackup() {
    const backupDataSource = BackupNativeDataSource();
    final backupRepo = BackupRepositoryImpl(dataSource: backupDataSource);
    return BackupController(
      exportUseCase: ExportTasksUseCase(backupRepo),
      importUseCase: ImportTasksUseCase(backupRepo),
      shareUseCase: ShareBackupUseCase(backupRepo),
    );
  }

  static WidgetSyncController _initWidgets(TaskController taskCtrl) {
    final widgetDataSource = WidgetNativeDataSource();
    final widgetRepo = WidgetSyncRepositoryImpl(dataSource: widgetDataSource);
    final widgetSyncCtrl = WidgetSyncController(
      syncUseCase: SyncWidgetSnapshotUseCase(widgetRepo),
      processTogglesUseCase: ProcessWidgetTogglesUseCase(widgetRepo),
    );

    widgetSyncCtrl.onExternalToggleHandler = (taskId) async {
      await taskCtrl.toggleCompleted(taskId);
    };

    // Auto-sync widget snapshot whenever tasks list updates
    taskCtrl.addListener(() {
      widgetSyncCtrl.syncFromTasks(tasks: taskCtrl.tasks);
    });

    // Check for toggles made from interactive widget while app was closed
    widgetSyncCtrl.processPendingToggles(
      onToggle: taskCtrl.toggleCompleted,
    );

    return widgetSyncCtrl;
  }

  static DailyDigestController _initDigest(SharedPreferences prefs) {
    final digestLocalDataSource = DailyDigestLocalDataSource(prefs);
    final digestRemoteDataSource = DailyDigestRemoteDataSource(prefs: prefs);
    final digestRepo = DailyDigestRepositoryImpl(
      localDataSource: digestLocalDataSource,
      remoteDataSource: digestRemoteDataSource,
    );
    return DailyDigestController(DailyDigestUseCase(digestRepo));
  }
}

/// Asynchronous bootstrap for loading storage and constructing the DI dependency graph.
Future<AppDependencies> setupDependencies({
  SharedPreferences? prefs,
  INotificationService? notificationService,
}) async {
  final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
  return AppDependencies.init(
    sharedPrefs,
    notificationService: notificationService,
  );
}
