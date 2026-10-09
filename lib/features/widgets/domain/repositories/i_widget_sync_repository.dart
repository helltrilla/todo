import 'package:todo/core/errors/result.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';

/// Pure Dart abstract repository interface for native iOS / Android widget synchronization.
abstract interface class IWidgetSyncRepository {
  /// Pushes current tasks & Pomodoro snapshot to native App Group / WidgetCenter.
  Future<Result<void>> syncSnapshot(WidgetSnapshot snapshot);

  /// Fetches task IDs that were toggled while the app was inactive (e.g. via iOS 17 interactive widgets).
  Future<Result<List<int>>> fetchPendingToggledTaskIds();

  /// Clears pending toggled task IDs after they have been processed by the Flutter app.
  Future<Result<void>> clearPendingToggledTaskIds();

  /// Real-time stream of task IDs toggled while the app is active in foreground or resumed.
  Stream<int> get externalToggledTaskIdStream;
}
