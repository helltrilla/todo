import 'package:todo/features/auth/domain/models/app_user.dart';

/// Domain interface for authentication.
/// Supports both internal local accounts and external Email OTP / Password via Supabase.
abstract interface class IAuthRepository {
  /// Returns the currently logged-in user if a session is active.
  AppUser? getCurrentUser();

  /// Internal registration: creates a local account with name, username/email, and password.
  Future<AppUser> registerInternal({
    required String name,
    required String login,
    required String password,
  });

  /// Internal sign-in: authenticates against locally stored accounts.
  Future<AppUser> signInInternal({
    required String login,
    required String password,
  });

  /// Sends a 6-digit OTP code to [email] via Supabase Auth.
  Future<void> sendEmailOtp({required String email, String? name});

  /// Verifies the 6-digit [code] sent to [email] via Supabase Auth and starts a session.
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  });

  /// Clears the active session.
  Future<void> signOut();
}
