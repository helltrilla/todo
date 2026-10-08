/// Configuration for Supabase Auth integration.
/// Supports compile-time overrides via `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jjntzrvkpyqfywjjczhk.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_JRfKYxK4Kje8Uqvk51qvfw_ibXK91SF',
  );
}
