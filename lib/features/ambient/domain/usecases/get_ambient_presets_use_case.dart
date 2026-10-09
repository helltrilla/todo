import 'package:todo/core/errors/result.dart';
import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';
import 'package:todo/features/ambient/domain/repositories/i_ambient_audio_repository.dart';

/// Atomic use case to fetch all configured ambient sound presets.
class GetAmbientPresetsUseCase {
  const GetAmbientPresetsUseCase(this._repository);

  final IAmbientAudioRepository _repository;

  Future<Result<List<AmbientSound>>> call() {
    return _repository.getPresets();
  }
}
