import 'package:flutter/foundation.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/digest/domain/usecases/daily_digest_use_case.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class DailyDigestController extends ChangeNotifier {
  final DailyDigestUseCase _digestUseCase;

  DailyDigestController(this._digestUseCase);

  DailyDigest? _digest;
  bool _isLoading = false;
  bool _isDismissed = false;
  String? _errorMessage;

  DailyDigest? get digest => _digest;
  bool get isLoading => _isLoading;
  bool get isDismissed => _isDismissed;
  String? get errorMessage => _errorMessage;
  bool get isVisible => !_isDismissed && (_isLoading || _digest != null);

  Future<void> loadDigest(List<Task> tasks, {bool force = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isDismissed = await _digestUseCase.isDismissed();
      final result = await _digestUseCase(
        tasks: tasks,
        forceRefresh: force,
      );
      _digest = result;
    } catch (e, st) {
      AppLogger.warning('DailyDigestController error', e, st);
      _errorMessage = 'Не удалось загрузить бриф';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(List<Task> tasks) async {
    await loadDigest(tasks, force: true);
  }

  Future<void> dismiss() async {
    _isDismissed = true;
    notifyListeners();
    try {
      await _digestUseCase.dismiss();
    } catch (e, st) {
      AppLogger.warning('Failed to persist digest dismiss', e, st);
    }
  }

  Future<void> restore() async {
    _isDismissed = false;
    notifyListeners();
    try {
      await _digestUseCase.restore();
    } catch (e, st) {
      AppLogger.warning('Failed to persist digest restore', e, st);
    }
  }
}
