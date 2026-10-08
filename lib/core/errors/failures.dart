/// Base class for all domain-level failures.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure originating from local storage / SharedPreferences.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure originating from remote server / Supabase API.
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure originating from network connectivity / timeouts.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure originating from invalid authentication credentials or input.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
