import 'package:todo/core/errors/result.dart';
import 'package:todo/features/productivity/domain/entities/productivity_dashboard.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Pure Dart abstract repository for calculating productivity analytics.
abstract interface class IProductivityRepository {
  /// Computes the complete dashboard metrics from [tasks] with target [daysRange] (default 120).
  Future<Result<ProductivityDashboard>> getDashboard({
    required List<Task> tasks,
    int daysRange = 120,
    DateTime? referenceDate,
  });
}
