import 'package:todo/core/errors/result.dart';
import 'package:todo/features/voice/domain/entities/speech_recognition_result.dart';

/// Pure Dart abstract repository interface for device speech recognition.
abstract interface class ISpeechRecognitionRepository {
  /// Checks whether speech recognition permissions are granted and engine is ready.
  Future<Result<bool>> initialize();

  /// Starts listening to audio input and emits streaming recognition results.
  Stream<Result<SpeechRecognitionResult>> startListening({
    String localeId = 'ru_RU',
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
  });

  /// Stops listening and commits final transcription.
  Future<Result<void>> stopListening();

  /// Cancels listening and discards buffer.
  Future<Result<void>> cancelListening();
}
