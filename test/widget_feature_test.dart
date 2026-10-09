import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';
import 'package:todo/features/widgets/data/models/widget_pomodoro_state_dto.dart';
import 'package:todo/features/widgets/data/models/widget_snapshot_dto.dart';
import 'package:todo/features/widgets/data/models/widget_task_item_dto.dart';
import 'package:todo/features/widgets/domain/entities/widget_pomodoro_state.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';
import 'package:todo/features/widgets/domain/entities/widget_task_item.dart';
import 'package:todo/features/widgets/domain/repositories/i_widget_sync_repository.dart';
import 'package:todo/features/widgets/domain/usecases/process_widget_toggles_use_case.dart';
import 'package:todo/features/widgets/domain/usecases/sync_widget_snapshot_use_case.dart';
import 'package:todo/features/widgets/presentation/controllers/widget_sync_controller.dart';

class _FakeWidgetSyncRepository implements IWidgetSyncRepository {
  WidgetSnapshot? lastSyncedSnapshot;
  List<int> pendingToggles = [];
  bool clearCalled = false;
  bool shouldFail = false;

  final StreamController<int> _externalStreamController =
      StreamController<int>.broadcast();

  void emitExternalToggle(int id) {
    _externalStreamController.add(id);
  }

  @override
  Future<Result<void>> syncSnapshot(WidgetSnapshot snapshot) async {
    if (shouldFail) {
      return const Error(ServerFailure('Widget sync failed in test'));
    }
    lastSyncedSnapshot = snapshot;
    return const Success(null);
  }

  @override
  Future<Result<List<int>>> fetchPendingToggledTaskIds() async {
    if (shouldFail) {
      return const Error(ServerFailure('Fetch pending failed in test'));
    }
    return Success(List.from(pendingToggles));
  }

  @override
  Future<Result<void>> clearPendingToggledTaskIds() async {
    if (shouldFail) {
      return const Error(ServerFailure('Clear pending failed in test'));
    }
    clearCalled = true;
    pendingToggles.clear();
    return const Success(null);
  }

  @override
  Stream<int> get externalToggledTaskIdStream =>
      _externalStreamController.stream;

  void dispose() {
    _externalStreamController.close();
  }
}

void main() {
  group('Widget Data Transfer Objects (DTO) serialization tests', () {
    test('WidgetTaskItemDto round-trip Map serialization', () {
      const item = WidgetTaskItem(
        id: 42,
        title: 'Review PR & Deploy',
        isCompleted: false,
        priorityIndex: 0,
        category: 'Work',
        dueDateLabel: '14:30',
      );

      final dto = WidgetTaskItemDto.fromDomain(item);
      final map = dto.toMap();

      expect(map['id'], equals(42));
      expect(map['title'], equals('Review PR & Deploy'));
      expect(map['isCompleted'], isFalse);
      expect(map['priorityIndex'], equals(0));
      expect(map['category'], equals('Work'));
      expect(map['dueDateLabel'], equals('14:30'));

      final restored = WidgetTaskItemDto.fromMap(map);
      expect(restored.id, equals(item.id));
      expect(restored.title, equals(item.title));
      expect(restored.isCompleted, equals(item.isCompleted));
      expect(restored.dueDateLabel, equals(item.dueDateLabel));
    });

    test('WidgetPomodoroStateDto calculates progress and formats time', () {
      const pomodoro = WidgetPomodoroState(
        isRunning: true,
        remainingSeconds: 600, // 10 minutes left
        totalSeconds: 1500, // 25 minutes total
        mode: 'focus',
        completedPomodoros: 4,
      );

      final dto = WidgetPomodoroStateDto.fromDomain(pomodoro);
      final map = dto.toMap();

      expect(map['isRunning'], isTrue);
      expect(map['remainingSeconds'], equals(600));
      expect(map['formattedRemaining'], equals('10:00'));
      expect(map['progressFraction'], closeTo(0.60, 0.01));

      final restored = WidgetPomodoroStateDto.fromMap(map);
      expect(restored.remainingSeconds, equals(600));
      expect(restored.completedPomodoros, equals(4));
    });

    test('WidgetSnapshotDto serializes to JSON string accurately', () {
      final now = DateTime(2026, 10, 9, 10, 0);
      final snapshot = WidgetSnapshot(
        tasks: const [
          WidgetTaskItem(
            id: 1,
            title: 'Task One',
            isCompleted: false,
            priorityIndex: 1,
            category: 'Personal',
          ),
        ],
        pomodoro: WidgetPomodoroState.idle,
        pendingCount: 1,
        completedCount: 0,
        updatedAt: now,
      );

      final dto = WidgetSnapshotDto.fromDomain(snapshot);
      final jsonStr = dto.toJson();

      expect(jsonStr, contains('"pendingCount":1'));
      expect(jsonStr, contains('"Task One"'));
      expect(jsonStr, contains('"Personal"'));

      final map = dto.toMap();
      final restored = WidgetSnapshotDto.fromMap(map);
      expect(restored.pendingCount, equals(1));
      expect(restored.tasks.length, equals(1));
      expect(restored.tasks.first.title, equals('Task One'));
    });
  });

  group('Clean Architecture Widget Use Cases & Controller tests', () {
    late _FakeWidgetSyncRepository fakeRepo;
    late SyncWidgetSnapshotUseCase syncUseCase;
    late ProcessWidgetTogglesUseCase processTogglesUseCase;
    late WidgetSyncController controller;

    setUp(() {
      fakeRepo = _FakeWidgetSyncRepository();
      syncUseCase = SyncWidgetSnapshotUseCase(fakeRepo);
      processTogglesUseCase = ProcessWidgetTogglesUseCase(fakeRepo);
      controller = WidgetSyncController(
        syncUseCase: syncUseCase,
        processTogglesUseCase: processTogglesUseCase,
      );
    });

    tearDown(() {
      controller.dispose();
      fakeRepo.dispose();
    });

    test(
      'SyncWidgetSnapshotUseCase syncs to repository successfully',
      () async {
        final snapshot = WidgetSnapshot(
          tasks: const [],
          pomodoro: WidgetPomodoroState.idle,
          pendingCount: 0,
          completedCount: 0,
          updatedAt: DateTime.now(),
        );

        final result = await syncUseCase(snapshot);
        expect(result, isA<Success<void>>());
        expect(fakeRepo.lastSyncedSnapshot, equals(snapshot));
      },
    );

    test(
      'ProcessWidgetTogglesUseCase fetches and automatically clears pending IDs',
      () async {
        fakeRepo.pendingToggles = [101, 102];

        final result = await processTogglesUseCase();
        expect(result, isA<Success<List<int>>>());
        final ids = (result as Success<List<int>>).data;
        expect(ids, equals([101, 102]));
        expect(fakeRepo.clearCalled, isTrue);
        expect(fakeRepo.pendingToggles, isEmpty);
      },
    );

    test(
      'WidgetSyncController transforms task list and prioritizes tasks correctly',
      () async {
        final now = DateTime.now();
        final tasks = [
          Task(
            id: 1,
            name: 'Low priority task',
            value: '',
            priorityIndex: 3, // P4
            isCompleted: false,
            createdAt: now,
          ),
          Task(
            id: 2,
            name: 'Urgent task',
            value: '',
            priorityIndex: 0, // P1
            isCompleted: false,
            createdAt: now,
          ),
          Task(
            id: 3,
            name: 'Finished task',
            value: '',
            priorityIndex: 1,
            isCompleted: true,
            createdAt: now,
          ),
        ];

        final success = await controller.syncFromTasks(tasks: tasks);
        expect(success, isTrue);
        expect(controller.isSyncing, isFalse);
        expect(controller.lastSyncTime, isNotNull);
        expect(controller.syncError, isNull);

        final synced = fakeRepo.lastSyncedSnapshot;
        expect(synced, isNotNull);
        expect(synced!.pendingCount, equals(2));
        expect(synced.completedCount, equals(1));
        // First task in widget list must be the highest priority (P1)
        expect(synced.tasks.first.id, equals(2));
        expect(synced.tasks.first.title, equals('Urgent task'));
      },
    );

    test(
      'WidgetSyncController handles real-time external stream toggle',
      () async {
        final toggledCompleter = Completer<int>();
        controller.onExternalToggleHandler = (id) async {
          toggledCompleter.complete(id);
        };

        fakeRepo.emitExternalToggle(555);

        final receivedId = await toggledCompleter.future;
        expect(receivedId, equals(555));
      },
    );

    test('WidgetSyncController records error on sync failure', () async {
      fakeRepo.shouldFail = true;
      final success = await controller.syncFromTasks(tasks: const []);
      expect(success, isFalse);
      expect(controller.syncError, contains('Widget sync failed'));
    });
  });
}
