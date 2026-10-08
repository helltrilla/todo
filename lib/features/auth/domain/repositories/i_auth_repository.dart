import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';

/// Domain interface for authentication.
/// All failable operations return a functional [Result<T>].
abstract interface class IAuthRepository {
  /// Returns the currently logged-in user if a session is active.
  AppUser? getCurrentUser();

  /// Internal registration: creates a local account with name, username/email, and password.
  Future<Result<AppUser>> registerInternal({
    required String name,
    required String login,
    required String password,
  });

  /// Internal sign-in: authenticates against locally stored accounts.
  Future<Result<AppUser>> signInInternal({
    required String login,
    required String password,
  });

  /// Sends a 6-digit OTP code to [email] via Supabase Auth.
  Future<Result<void>> sendEmailOtp({required String email, String? name});

  /// Verifies the 6-digit [code] sent to [email] via Supabase Auth and starts a session.
  Future<Result<AppUser>> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  });

  /// Updates the current user's display name.
  Future<Result<AppUser>> updateDisplayName(String newName);

  /// Clears the active session.
  Future<Result<void>> signOut();

  /// Permanently deletes the current user account and associated credentials.
  Future<Result<void>> deleteAccount();

  /// Returns true if the user has already completed the first-launch onboarding or logged in.
  bool hasSeenOnboarding();

  /// Marks the first-launch onboarding as seen.
  Future<void> completeOnboarding();
}
