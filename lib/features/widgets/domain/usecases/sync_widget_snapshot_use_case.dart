import 'package:todo/core/errors/result.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';
import 'package:todo/features/widgets/domain/repositories/i_widget_sync_repository.dart';

/// Atomic usecase responsible for synchronizing app snapshot into native Widget storage.
class SyncWidgetSnapshotUseCase {
  const SyncWidgetSnapshotUseCase(this._repository);

  final IWidgetSyncRepository _repository;

  Future<Result<void>> call(WidgetSnapshot snapshot) {
    return _repository.syncSnapshot(snapshot);
  }
}
