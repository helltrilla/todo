import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/digest/domain/repositories/i_daily_digest_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class DailyDigestUseCase {
  final IDailyDigestRepository _repository;

  const DailyDigestUseCase(this._repository);

  Future<DailyDigest> call({
    required List<Task> tasks,
    bool forceRefresh = false,
  }) {
    return _repository.getDailyDigest(
      tasks: tasks,
      forceRefresh: forceRefresh,
    );
  }

  Future<bool> isDismissed() => _repository.isDigestDismissedToday();

  Future<void> dismiss() => _repository.dismissDigestToday();

  Future<void> restore() => _repository.restoreDigestToday();
}
