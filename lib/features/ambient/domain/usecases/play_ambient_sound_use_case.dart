import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Atomic use case to start or resume playing a designated ambient soundscape.
class PlayAmbientSoundUseCase {
  const PlayAmbientSoundUseCase(this._repository);

  final IAmbientAudioRepository _repository;

  Future<Result<void>> call({required String soundId, double? volume}) {
    if (soundId.trim().isEmpty) {
      return Future.value(
        const Error(ServerFailure('Идентификатор звука не может быть пустым')),
      );
    }
    if (volume != null && (volume < 0.0 || volume > 1.0)) {
      return Future.value(
        const Error(
          ServerFailure('Громкость звука должна быть в пределах от 0.0 до 1.0'),
        ),
      );
    }
    return _repository.play(soundId: soundId, volume: volume);
  }
}
