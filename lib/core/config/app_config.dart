import 'package:todo/core/logging/app_logger.dart';

/// Global application configuration resolved via `--dart-define` or `--dart-define-from-file`.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Current semantic version of the application.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '2.0.1',
  );

  /// Backup payload schema version for data format migration and compatibility.
  static const int schemaVersion = 1;

  /// Whether valid Supabase backend credentials were provided in the build environment.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Validates application configuration at startup.
  ///
  /// Emits an informative warning if Supabase credentials are absent so the app
  /// can operate safely in offline/local-only mode without runtime crashes.
  static bool validate() {
    if (!isConfigured) {
      AppLogger.warning(
        'AppConfig: SUPABASE_URL or SUPABASE_ANON_KEY is not defined. '
        'Remote cloud synchronization and Supabase Auth are running in offline fallback mode. '
        'Pass keys via --dart-define or --dart-define-from-file=.env to enable cloud features.',
      );
      return false;
    }
    return true;
  }
}
