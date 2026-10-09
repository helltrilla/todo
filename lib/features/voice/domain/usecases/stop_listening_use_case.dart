import 'package:todo/core/errors/result.dart';
import 'package:todo/features/voice/domain/repositories/i_speech_recognition_repository.dart';

/// Use case that closes audio session and stops recording.
class StopListeningUseCase {
  const StopListeningUseCase(this._repository);

  final ISpeechRecognitionRepository _repository;

  Future<Result<void>> call() => _repository.stopListening();
}
