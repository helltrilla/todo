import 'package:todo/core/errors/result.dart';
import 'package:todo/features/voice/domain/repositories/i_speech_recognition_repository.dart';

/// Use case that requests native microphone/speech permissions and boots engine.
class InitializeSpeechUseCase {
  const InitializeSpeechUseCase(this._repository);

  final ISpeechRecognitionRepository _repository;

  Future<Result<bool>> call() => _repository.initialize();
}
