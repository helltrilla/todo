import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Atomic use case to pause active ambient audio playback.
class PauseAmbientSoundUseCase {
  const PauseAmbientSoundUseCase(this._repository);

  final IAmbientAudioRepository _repository;

  Future<Result<void>> call() {
    return _repository.pause();
  }
}
