import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_local_data_source.dart';
import 'package:todo/features/digest/data/datasources/daily_digest_remote_data_source.dart';
import 'package:todo/features/digest/data/services/heuristic_digest_generator.dart';
import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/digest/domain/repositories/i_daily_digest_repository.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

class DailyDigestRepositoryImpl implements IDailyDigestRepository {
  final IDailyDigestLocalDataSource _localDataSource;
  final IDailyDigestRemoteDataSource _remoteDataSource;
  final HeuristicDigestGenerator _heuristicGenerator;

  DailyDigestRepositoryImpl({
    required IDailyDigestLocalDataSource localDataSource,
    required IDailyDigestRemoteDataSource remoteDataSource,
    HeuristicDigestGenerator? heuristicGenerator,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _heuristicGenerator = heuristicGenerator ?? const HeuristicDigestGenerator();

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Future<DailyDigest> getDailyDigest({
    required List<Task> tasks,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final key = _dateKey(now);

    if (!forceRefresh) {
      final cached = await _localDataSource.getCachedDigest(key);
      if (cached != null) {
        return cached;
      }
    }

    final pending = tasks.where((t) => !t.isCompleted && !t.isArchived).toList();
    if (pending.isEmpty) {
      final defaultDigest = _heuristicGenerator.generate(
        tasks: tasks,
        referenceTime: now,
      );
      await _localDataSource.saveCachedDigest(key, defaultDigest);
      return defaultDigest;
    }

    DailyDigest? result;
    try {
      result = await _remoteDataSource.generateDigest(
        tasks: tasks,
        referenceTime: now,
      );
    } catch (e, st) {
      AppLogger.warning('Error in remote daily digest generation', e, st);
    }

    result ??= _heuristicGenerator.generate(
      tasks: tasks,
      referenceTime: now,
    );

    await _localDataSource.saveCachedDigest(key, result);
    return result;
  }

  @override
  Future<bool> isDigestDismissedToday() async {
    final key = _dateKey(DateTime.now());
    return _localDataSource.isDismissed(key);
  }

  @override
  Future<void> dismissDigestToday() async {
    final key = _dateKey(DateTime.now());
    await _localDataSource.setDismissed(key, true);
  }

  @override
  Future<void> restoreDigestToday() async {
    final key = _dateKey(DateTime.now());
    await _localDataSource.setDismissed(key, false);
  }
}
