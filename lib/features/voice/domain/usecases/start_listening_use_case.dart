import 'package:todo/core/errors/result.dart';
import 'package:todo/features/voice/domain/entities/speech_recognition_result.dart';
import 'package:todo/features/voice/domain/repositories/i_speech_recognition_repository.dart';

/// Use case that opens audio capture and streams speech tokens in real-time.
class StartListeningUseCase {
  const StartListeningUseCase(this._repository);

  final ISpeechRecognitionRepository _repository;

  Stream<Result<SpeechRecognitionResult>> call({
    String localeId = 'ru_RU',
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
  }) {
    return _repository.startListening(
      localeId: localeId,
      pauseFor: pauseFor,
      listenFor: listenFor,
    );
  }
}
