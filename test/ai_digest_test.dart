import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_local_data_source.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_remote_data_source.dart';
import 'package:todo/features/digest/data/repositories/daily_digest_repository_impl.dart';
import 'package:todo/features/digest/data/services/heuristic_digest_generator.dart';
import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/digest/domain/usecases/daily_digest_use_case.dart';
import 'package:todo/features/digest/presentation/controllers/daily_digest_controller.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class MockRemoteDataSource implements IDailyDigestRemoteDataSource {
  DailyDigest? responseToReturn;
  int callCount = 0;

  @override
  Future<DailyDigest?> generateDigest({
    required List<Task> tasks,
    DateTime? referenceTime,
  }) async {
    callCount++;
    return responseToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeuristicDigestGenerator', () {
    const generator = HeuristicDigestGenerator();

    test('returns clean slate message when task list is empty', () {
      final digest = generator.generate(tasks: const []);
      expect(digest.headline, contains('Чистый лист'));
      expect(digest.isFallback, isTrue);
      expect(digest.topFocus, isNotEmpty);
      expect(digest.summary, isNotEmpty);
    });

    test('returns victory message when all active tasks are completed', () {
      final task = Task(
        id: 1,
        name: 'Купить хлеб',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1,
        isCompleted: true,
      );
      final digest = generator.generate(tasks: [task]);
      expect(digest.headline, contains('Все задачи закрыты'));
      expect(digest.isFallback, isTrue);
    });

    test('identifies top priority task and recommends appropriate time slot', () {
      final t1 = Task(
        id: 1,
        name: 'Обычная задача',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 3,
      );
      final t2 = Task(
        id: 2,
        name: 'Срочный релиз',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
      );

      final morningTime = DateTime(2026, 10, 9, 9, 30);
      final digest = generator.generate(
        tasks: [t1, t2],
        referenceTime: morningTime,
      );

      expect(digest.topFocus, equals('Срочный релиз'));
      expect(digest.headline, contains('Фокус дня'));
      expect(digest.productivitySlot, contains('10:00 – 12:30'));
      expect(digest.summary, contains('Срочный релиз'));
    });
  });

  group('DailyDigestLocalDataSource & Repository', () {
    late SharedPreferences prefs;
    late DailyDigestLocalDataSource localDataSource;
    late MockRemoteDataSource mockRemoteDataSource;
    late DailyDigestRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = DailyDigestLocalDataSource(prefs);
      mockRemoteDataSource = MockRemoteDataSource();
      repository = DailyDigestRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('caches generated digest and reuses on subsequent calls without remote call', () async {
      final task = Task(
        id: 1,
        name: 'Развернуть бэкенд',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 0,
      );

      mockRemoteDataSource.responseToReturn = DailyDigest(
        headline: 'ИИ Утренний Фокус',
        topFocus: 'Развернуть бэкенд',
        productivitySlot: '11:00 - 13:00',
        summary: 'Начните день с деплоя.',
        generatedAt: DateTime.now(),
        isFallback: false,
      );

      final firstResult = await repository.getDailyDigest(tasks: [task]);
      expect(firstResult.headline, equals('ИИ Утренний Фокус'));
      expect(mockRemoteDataSource.callCount, equals(1));

      // Second call without forceRefresh must return cached immediately
      final secondResult = await repository.getDailyDigest(tasks: [task]);
      expect(secondResult.headline, equals('ИИ Утренний Фокус'));
      expect(mockRemoteDataSource.callCount, equals(1)); // Still 1!
    });

    test('falls back to heuristic generator when remote dataSource returns null', () async {
      final task = Task(
        id: 1,
        name: 'Подготовить отчет',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1,
      );

      mockRemoteDataSource.responseToReturn = null; // simulate offline/timeout

      final result = await repository.getDailyDigest(tasks: [task]);
      expect(result.isFallback, isTrue);
      expect(result.topFocus, equals('Подготовить отчет'));
      expect(mockRemoteDataSource.callCount, equals(1));
    });

    test('persists and restores dismiss state for today', () async {
      expect(await repository.isDigestDismissedToday(), isFalse);
      await repository.dismissDigestToday();
      expect(await repository.isDigestDismissedToday(), isTrue);
      await repository.restoreDigestToday();
      expect(await repository.isDigestDismissedToday(), isFalse);
    });
  });

  group('DailyDigestController & DailyDigestUseCase', () {
    late SharedPreferences prefs;
    late DailyDigestLocalDataSource localDataSource;
    late MockRemoteDataSource mockRemoteDataSource;
    late DailyDigestRepositoryImpl repository;
    late DailyDigestUseCase useCase;
    late DailyDigestController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = DailyDigestLocalDataSource(prefs);
      mockRemoteDataSource = MockRemoteDataSource();
      repository = DailyDigestRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: mockRemoteDataSource,
      );
      useCase = DailyDigestUseCase(repository);
      controller = DailyDigestController(useCase);
    });

    test('controller manages lifecycle: loadDigest, isVisible, and dismiss', () async {
      final task = Task(
        id: 1,
        name: 'Тестовая цель',
        value: '',
        createdAt: DateTime.now(),
        priorityIndex: 1,
      );

      expect(controller.isLoading, isFalse);
      expect(controller.digest, isNull);

      await controller.loadDigest([task]);

      expect(controller.isLoading, isFalse);
      expect(controller.digest, isNotNull);
      expect(controller.isVisible, isTrue);

      await controller.dismiss();
      expect(controller.isDismissed, isTrue);
      expect(controller.isVisible, isFalse);

      await controller.restore();
      expect(controller.isDismissed, isFalse);
      expect(controller.isVisible, isTrue);
    });
  });
}
