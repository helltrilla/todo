import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/widgets/domain/entities/widget_pomodoro_state.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';
import 'package:todo/features/widgets/domain/entities/widget_task_item.dart';
import 'package:todo/features/widgets/domain/usecases/process_widget_toggles_use_case.dart';
import 'package:todo/features/widgets/domain/usecases/sync_widget_snapshot_use_case.dart';

/// Presentation state controller managing iOS / Android widget synchronization.
/// Interacts ONLY through Use Cases, never directly with Repositories or DataSources.
class WidgetSyncController extends ChangeNotifier {
  WidgetSyncController({
    required SyncWidgetSnapshotUseCase syncUseCase,
    required ProcessWidgetTogglesUseCase processTogglesUseCase,
  }) : _syncUseCase = syncUseCase,
       _processTogglesUseCase = processTogglesUseCase {
    _streamSubscription = _processTogglesUseCase.externalToggledStream.listen(
      _onExternalTaskToggled,
    );
  }

  final SyncWidgetSnapshotUseCase _syncUseCase;
  final ProcessWidgetTogglesUseCase _processTogglesUseCase;
  StreamSubscription<int>? _streamSubscription;

  Future<void> Function(int taskId)? onExternalToggleHandler;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;

  void _onExternalTaskToggled(int taskId) {
    onExternalToggleHandler?.call(taskId);
  }

  /// Transforms the current Flutter tasks and Pomodoro state into a [WidgetSnapshot]
  /// and synchronizes it to the native App Group container.
  Future<bool> syncFromTasks({
    required List<Task> tasks,
    WidgetPomodoroState? pomodoro,
  }) async {
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    // Prioritize active (uncompleted) tasks first, sorted by priority (P1..P4),
    // then due date, followed by recently completed tasks.
    final pending = tasks.where((t) => !t.isCompleted && !t.isArchived).toList()
      ..sort((a, b) {
        final pCompare = a.priorityIndex.compareTo(b.priorityIndex);
        if (pCompare != 0) return pCompare;
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    final completed =
        tasks.where((t) => t.isCompleted && !t.isArchived).toList()..sort(
          (a, b) => (b.completedAt ?? b.createdAt).compareTo(
            a.completedAt ?? a.createdAt,
          ),
        );

    final widgetItems = <WidgetTaskItem>[];

    for (final t in pending.take(8)) {
      widgetItems.add(
        WidgetTaskItem(
          id: t.id,
          title: t.name,
          isCompleted: false,
          priorityIndex: t.priorityIndex,
          category: t.category,
          dueDateLabel: t.reminderLabel,
        ),
      );
    }

    for (final t in completed.take(4)) {
      widgetItems.add(
        WidgetTaskItem(
          id: t.id,
          title: t.name,
          isCompleted: true,
          priorityIndex: t.priorityIndex,
          category: t.category,
          dueDateLabel: t.reminderLabel,
        ),
      );
    }

    final snapshot = WidgetSnapshot(
      tasks: widgetItems,
      pomodoro: pomodoro ?? WidgetPomodoroState.idle,
      pendingCount: pending.length,
      completedCount: completed.length,
      updatedAt: DateTime.now(),
    );

    final result = await _syncUseCase(snapshot);
    _isSyncing = false;

    switch (result) {
      case Success():
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return true;
      case Error(:final failure):
        _syncError = failure.message;
        notifyListeners();
        return false;
    }
  }

  /// Checks for any tasks that the user marked complete from the iOS 17 interactive widget
  /// while the Flutter app was backgrounded or closed.
  Future<List<int>> processPendingToggles({
    Future<void> Function(int taskId)? onToggle,
  }) async {
    final result = await _processTogglesUseCase();
    switch (result) {
      case Success(:final data):
        for (final id in data) {
          if (onToggle != null) {
            await onToggle(id);
          } else if (onExternalToggleHandler != null) {
            await onExternalToggleHandler!(id);
          }
        }
        return data;
      case Error(:final failure):
        _syncError = failure.message;
        notifyListeners();
        return const [];
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
