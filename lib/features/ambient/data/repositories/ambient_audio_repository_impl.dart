import 'dart:async';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/data/datasources/ambient_audio_native_data_source.dart';
import 'package:todo/features/ambient/domain/entities/ambient_playback_state.dart';
import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Clean Architecture repository implementation for ambient audio soundscapes.
/// Traps platform and datasource exceptions and yields typed [Result] monads.
class AmbientAudioRepositoryImpl implements IAmbientAudioRepository {
  AmbientAudioRepositoryImpl({required AmbientAudioNativeDataSource dataSource})
    : _dataSource = dataSource;

  final AmbientAudioNativeDataSource _dataSource;

  @override
  Stream<AmbientPlaybackState> get stateChanges => _dataSource.stateStream;

  @override
  Future<Result<List<AmbientSound>>> getPresets() async {
    try {
      final models = await _dataSource.getPresets();
      return Success(models);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось загрузить список звуков: $e'));
    }
  }

  @override
  Future<Result<void>> play({required String soundId, double? volume}) async {
    try {
      await _dataSource.play(soundId: soundId, volume: volume);
      return const Success(null);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось запустить воспроизведение: $e'));
    }
  }

  @override
  Future<Result<void>> pause() async {
    try {
      await _dataSource.pause();
      return const Success(null);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(
        ServerFailure('Не удалось приостановить воспроизведение: $e'),
      );
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _dataSource.stop();
      return const Success(null);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось остановить воспроизведение: $e'));
    }
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    try {
      await _dataSource.setVolume(volume);
      return const Success(null);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось изменить громкость: $e'));
    }
  }

  @override
  Future<Result<AmbientPlaybackState>> getCurrentState() async {
    try {
      final state = await _dataSource.getCurrentState();
      return Success(state);
    } on AmbientAudioNativeException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Не удалось получить статус аудио: $e'));
    }
  }
}
