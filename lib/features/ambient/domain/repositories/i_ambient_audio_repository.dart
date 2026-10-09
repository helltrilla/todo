import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/entities/ambient_playback_state.dart';
import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';

/// Pure Dart abstract repository interface for ambient audio playback.
abstract interface class IAmbientAudioRepository {
  /// Retrieves available built-in ambient presets.
  Future<Result<List<AmbientSound>>> getPresets();

  /// Starts or switches playback to [soundId] at [volume] (0.0 .. 1.0).
  Future<Result<void>> play({required String soundId, double? volume});

  /// Pauses ambient playback without resetting the active sound.
  Future<Result<void>> pause();

  /// Stops ambient audio playback and releases resources.
  Future<Result<void>> stop();

  /// Adjusts ambient playback volume (0.0 .. 1.0).
  Future<Result<void>> setVolume(double volume);

  /// Retrieves the current hardware / native playback state.
  Future<Result<AmbientPlaybackState>> getCurrentState();

  /// Stream of ambient state updates (e.g. from lock screen or interruptions).
  Stream<AmbientPlaybackState> get stateChanges;
}
