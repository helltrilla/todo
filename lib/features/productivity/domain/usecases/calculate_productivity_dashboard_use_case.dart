import 'package:todo/core/errors/result.dart';
import 'package:todo/features/productivity/domain/entities/productivity_dashboard.dart';
import 'package:todo/features/productivity/domain/repositories/i_productivity_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Atomic use case that aggregates thousands of tasks into comprehensive productivity analytics.
class CalculateProductivityDashboardUseCase {
  const CalculateProductivityDashboardUseCase(this._repository);

  final IProductivityRepository _repository;

  Future<Result<ProductivityDashboard>> call({
    required List<Task> tasks,
    int daysRange = 120,
    DateTime? referenceDate,
  }) {
    return _repository.getDashboard(
      tasks: tasks,
      daysRange: daysRange,
      referenceDate: referenceDate,
    );
  }
}
