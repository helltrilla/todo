/// Global application configuration resolved via `--dart-define`.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jjntzrvkpyqfywjjczhk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_JRfKYxK4Kje8Uqvk51qvfw_ibXK91SF',
  );
}
