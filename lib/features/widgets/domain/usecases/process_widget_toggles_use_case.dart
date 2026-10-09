import 'package:todo/core/errors/result.dart';
import 'package:todo/features/widgets/domain/repositories/i_widget_sync_repository.dart';

/// Atomic usecase responsible for retrieving and clearing pending widget toggles.
class ProcessWidgetTogglesUseCase {
  const ProcessWidgetTogglesUseCase(this._repository);

  final IWidgetSyncRepository _repository;

  /// Fetches pending toggled task IDs and clears them from native storage in a transaction.
  Future<Result<List<int>>> call() async {
    final fetchResult = await _repository.fetchPendingToggledTaskIds();
    switch (fetchResult) {
      case Success(:final data):
        if (data.isNotEmpty) {
          await _repository.clearPendingToggledTaskIds();
        }
        return Success(data);
      case Error():
        return fetchResult;
    }
  }

  Stream<int> get externalToggledStream =>
      _repository.externalToggledTaskIdStream;
}
