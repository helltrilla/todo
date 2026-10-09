import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/productivity/domain/entities/heatmap_day.dart';
import 'package:todo/features/productivity/domain/entities/productivity_dashboard.dart';
import 'package:todo/features/productivity/domain/usecases/calculate_productivity_dashboard_use_case.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Presentation state controller managing Productivity Dashboard analytics.
/// Interacts STRICTLY with Use Cases; never touches data sources directly.
class ProductivityController extends ChangeNotifier {
  ProductivityController({
    required CalculateProductivityDashboardUseCase calculateDashboardUseCase,
  }) : _calculateDashboardUseCase = calculateDashboardUseCase;

  final CalculateProductivityDashboardUseCase _calculateDashboardUseCase;

  ProductivityDashboard _dashboard = ProductivityDashboard.empty;
  HeatmapDay? _selectedDay;
  bool _isLoading = false;
  String? _errorMessage;

  ProductivityDashboard get dashboard => _dashboard;
  HeatmapDay? get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> computeDashboard(List<Task> tasks) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _calculateDashboardUseCase(tasks: tasks);

    if (result is Success<ProductivityDashboard>) {
      _dashboard = result.data;
      _isLoading = false;
      notifyListeners();
    } else if (result is Error<ProductivityDashboard>) {
      _errorMessage = result.failure.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDay(HeatmapDay? day) {
    if (_selectedDay == day) {
      _selectedDay = null;
    } else {
      _selectedDay = day;
    }
    notifyListeners();
  }
}
