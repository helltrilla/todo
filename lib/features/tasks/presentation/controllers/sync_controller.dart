import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/entities/sync_status.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';
import 'package:todo/features/tasks/domain/usecases/sync_tasks_use_case.dart';

/// Presentation controller orchestrating cloud data synchronization.
/// Tracks sync lifecycle [SyncStatus], error states, and last synced timestamp.
class SyncController extends ChangeNotifier {
  SyncController({
    required SyncTasksUseCase syncUseCase,
    this.onTasksSynced,
  }) : _syncUseCase = syncUseCase;

  final SyncTasksUseCase _syncUseCase;

  /// Callback to notify task controller or listeners when remote dataset is fetched.
  final void Function(List<Task> tasks)? onTasksSynced;

  SyncStatus _status = SyncStatus.idle;
  String? _syncError;
  DateTime? _lastSyncedAt;

  SyncStatus get status => _status;
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get hasSyncError => _status == SyncStatus.error;
  bool get isSuccess => _status == SyncStatus.success;
  String? get syncError => _syncError;
  DateTime? get lastSyncedAt =>
      _lastSyncedAt ?? _syncUseCase.repository.lastSyncedAt;

  Future<bool> syncWithCloud() async {
    if (_status == SyncStatus.syncing) return false;

    _status = SyncStatus.syncing;
    _syncError = null;
    notifyListeners();

    final result = await _syncUseCase();

    switch (result) {
      case Success(:final data):
        _status = SyncStatus.success;
        _lastSyncedAt = DateTime.now();
        _syncError = null;
        if (onTasksSynced != null) {
          onTasksSynced!(data);
        }
        notifyListeners();
        return true;

      case Error(:final failure):
        _status = SyncStatus.error;
        _syncError = failure.message;
        notifyListeners();
        return false;
    }
  }

  void clearError() {
    _syncError = null;
    if (_status == SyncStatus.error) {
      _status = SyncStatus.idle;
    }
    notifyListeners();
  }
}
