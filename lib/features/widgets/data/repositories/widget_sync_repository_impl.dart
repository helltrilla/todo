import 'package:flutter/services.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/widgets/data/datasources/widget_native_data_source.dart';
import 'package:todo/features/widgets/data/models/widget_snapshot_dto.dart';
import 'package:todo/features/widgets/domain/entities/widget_snapshot.dart';
import 'package:todo/features/widgets/domain/repositories/i_widget_sync_repository.dart';

/// Clean Architecture repository implementation for Widget synchronization.
class WidgetSyncRepositoryImpl implements IWidgetSyncRepository {
  const WidgetSyncRepositoryImpl({required WidgetNativeDataSource dataSource})
    : _dataSource = dataSource;

  final WidgetNativeDataSource _dataSource;

  @override
  Future<Result<void>> syncSnapshot(WidgetSnapshot snapshot) async {
    try {
      final dto = WidgetSnapshotDto.fromDomain(snapshot);
      await _dataSource.syncWidgetData(dto.toMap());
      return const Success(null);
    } on PlatformException catch (e) {
      return Error(ServerFailure('Widget sync error: ${e.message}'));
    } catch (e) {
      return Error(ServerFailure('Widget sync failure: $e'));
    }
  }

  @override
  Future<Result<List<int>>> fetchPendingToggledTaskIds() async {
    try {
      final ids = await _dataSource.getPendingToggledTaskIds();
      return Success(ids);
    } on PlatformException catch (e) {
      return Error(ServerFailure('Fetch pending toggles error: ${e.message}'));
    } catch (e) {
      return Error(ServerFailure('Fetch pending toggles failure: $e'));
    }
  }

  @override
  Future<Result<void>> clearPendingToggledTaskIds() async {
    try {
      await _dataSource.clearPendingToggledTaskIds();
      return const Success(null);
    } on PlatformException catch (e) {
      return Error(ServerFailure('Clear pending toggles error: ${e.message}'));
    } catch (e) {
      return Error(ServerFailure('Clear pending toggles failure: $e'));
    }
  }

  @override
  Stream<int> get externalToggledTaskIdStream => _dataSource.toggledTaskStream;
}
