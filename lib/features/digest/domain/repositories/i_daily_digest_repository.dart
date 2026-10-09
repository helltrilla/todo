import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

abstract interface class IDailyDigestRepository {
  /// Retrieves or generates the daily digest for [tasks].
  /// If [forceRefresh] is false and a digest was already cached today, returns cached.
  Future<DailyDigest> getDailyDigest({
    required List<Task> tasks,
    bool forceRefresh = false,
  });

  /// Checks if the digest was explicitly dismissed by user today.
  Future<bool> isDigestDismissedToday();

  /// Marks today's digest as dismissed.
  Future<void> dismissDigestToday();

  /// Clears dismiss flag for today's digest.
  Future<void> restoreDigestToday();
}
