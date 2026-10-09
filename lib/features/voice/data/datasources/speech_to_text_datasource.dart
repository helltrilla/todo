import 'dart:async';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt_lib;

/// Low-level typed exception thrown by the speech-to-text platform channel.
class SpeechNativeException implements Exception {
  final String message;
  const SpeechNativeException(this.message);

  @override
  String toString() => message;
}

/// DTO emitted by [SpeechToTextDataSource] carrying recognized text and audio level.
class SpeechRawSnapshot {
  const SpeechRawSnapshot({
    required this.words,
    required this.confidence,
    required this.isFinal,
    required this.soundLevelDb,
  });

  final String words;
  final double confidence;
  final bool isFinal;
  final double soundLevelDb;
}

class SpeechToTextDataSource {
  SpeechToTextDataSource({stt_lib.SpeechToText? engine})
    : _speech = engine ?? stt_lib.SpeechToText();

  final stt_lib.SpeechToText _speech;
  StreamController<SpeechRawSnapshot>? _activeStreamController;
  double _lastSoundLevel = 0.0;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;

  Future<bool> initialize() async {
    try {
      final initialized = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          _activeStreamController?.addError(
            SpeechNativeException(error.errorMsg),
          );
        },
        debugLogging: false,
      );
      return initialized;
    } catch (e) {
      throw SpeechNativeException(
        'Ошибка инициализации распознавания речи: $e',
      );
    }
  }

  Stream<SpeechRawSnapshot> listenStream({
    required String localeId,
    required Duration pauseFor,
    required Duration listenFor,
  }) {
    _activeStreamController?.close();
    final controller = StreamController<SpeechRawSnapshot>.broadcast();
    _activeStreamController = controller;

    _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        if (!controller.isClosed) {
          controller.add(
            SpeechRawSnapshot(
              words: result.recognizedWords,
              confidence: result.confidence,
              isFinal: result.finalResult,
              soundLevelDb: _lastSoundLevel,
            ),
          );
          if (result.finalResult && !controller.isClosed) {
            controller.close();
          }
        }
      },
      onSoundLevelChange: (level) {
        _lastSoundLevel = level;
      },
      listenOptions: stt_lib.SpeechListenOptions(
        listenMode: stt_lib.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
        pauseFor: pauseFor,
        listenFor: listenFor,
        localeId: localeId,
      ),
    );

    return controller.stream;
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (e) {
      throw SpeechNativeException('Не удалось остановить запись: $e');
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _activeStreamController?.close();
    } catch (e) {
      throw SpeechNativeException('Не удалось отменить запись: $e');
    }
  }
}
