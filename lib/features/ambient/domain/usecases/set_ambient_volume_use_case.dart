import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Atomic use case to update ambient audio volume level.
class SetAmbientVolumeUseCase {
  const SetAmbientVolumeUseCase(this._repository);

  final IAmbientAudioRepository _repository;

  Future<Result<void>> call(double volume) {
    if (volume < 0.0 || volume > 1.0) {
      return Future.value(
        const Error(
          ServerFailure('Громкость должна быть в диапазоне от 0.0 до 1.0'),
        ),
      );
    }
    return _repository.setVolume(volume);
  }
}
