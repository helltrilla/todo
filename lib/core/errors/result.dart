import 'package:todo/core/errors/failures.dart';

/// Functional Result monad representing either a [Success] value or an [Error] with a [Failure].
/// Eliminates uncaught exceptions and generic try/catch in the presentation layer.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
