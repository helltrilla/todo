import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Atomic use case to stop ambient audio playback and turn sound generator off.
class StopAmbientSoundUseCase {
  const StopAmbientSoundUseCase(this._repository);

  final IAmbientAudioRepository _repository;

  Future<Result<void>> call() {
    return _repository.stop();
  }
}
