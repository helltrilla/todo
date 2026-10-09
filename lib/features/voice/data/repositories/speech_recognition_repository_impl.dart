import 'dart:async';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/voice/data/datasources/speech_to_text_datasource.dart';
import 'package:todo/features/voice/domain/entities/speech_recognition_result.dart';
import 'package:todo/features/voice/domain/repositories/i_speech_recognition_repository.dart';

class SpeechRecognitionRepositoryImpl implements ISpeechRecognitionRepository {
  SpeechRecognitionRepositoryImpl({required SpeechToTextDataSource dataSource})
    : _dataSource = dataSource;

  final SpeechToTextDataSource _dataSource;

  @override
  Future<Result<bool>> initialize() async {
    try {
      final available = await _dataSource.initialize();
      return Success(available);
    } on SpeechNativeException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure('Непредвиденный сбой микрофона: $e'));
    }
  }

  @override
  Stream<Result<SpeechRecognitionResult>> startListening({
    String localeId = 'ru_RU',
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
  }) async* {
    try {
      final rawStream = _dataSource.listenStream(
        localeId: localeId,
        pauseFor: pauseFor,
        listenFor: listenFor,
      );

      await for (final raw in rawStream) {
        yield Success(
          SpeechRecognitionResult(
            recognizedWords: raw.words,
            confidence: raw.confidence,
            isFinal: raw.isFinal,
            soundLevelDb: raw.soundLevelDb,
          ),
        );
      }
    } on SpeechNativeException catch (e) {
      yield Error(ServerFailure(e.message));
    } catch (e) {
      yield Error(ServerFailure('Сбой потока распознавания речи: $e'));
    }
  }

  @override
  Future<Result<void>> stopListening() async {
    try {
      await _dataSource.stop();
      return const Success(null);
    } on SpeechNativeException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure('Сбой остановки распознавания: $e'));
    }
  }

  @override
  Future<Result<void>> cancelListening() async {
    try {
      await _dataSource.cancel();
      return const Success(null);
    } on SpeechNativeException catch (e) {
      return Error(CacheFailure(e.message));
    } catch (e) {
      return Error(CacheFailure('Сбой отмены распознавания: $e'));
    }
  }
}
