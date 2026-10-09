import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';
import 'package:todo/features/voice/domain/entities/speech_recognition_result.dart';
import 'package:todo/features/voice/domain/repositories/i_speech_recognition_repository.dart';
import 'package:todo/features/voice/domain/usecases/initialize_speech_use_case.dart';
import 'package:todo/features/voice/domain/usecases/process_voice_task_use_case.dart';
import 'package:todo/features/voice/domain/usecases/start_listening_use_case.dart';
import 'package:todo/features/voice/domain/usecases/stop_listening_use_case.dart';
import 'package:todo/features/voice/presentation/controllers/voice_task_controller.dart';

class FakeSpeechRepo implements ISpeechRecognitionRepository {
  bool isInitialized = false;
  bool isListening = false;
  StreamController<Result<SpeechRecognitionResult>>? _controller;

  @override
  Future<Result<bool>> initialize() async {
    isInitialized = true;
    return const Success(true);
  }

  @override
  Stream<Result<SpeechRecognitionResult>> startListening({
    String localeId = 'ru_RU',
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
  }) {
    isListening = true;
    _controller = StreamController<Result<SpeechRecognitionResult>>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<Result<void>> stopListening() async {
    isListening = false;
    _controller?.close();
    return const Success(null);
  }

  @override
  Future<Result<void>> cancelListening() async {
    isListening = false;
    _controller?.close();
    return const Success(null);
  }

  void emitResult(SpeechRecognitionResult res) {
    _controller?.add(Success(res));
  }
}

class FakeSmartTaskParser implements ISmartTaskParser {
  @override
  bool get hasGeminiApiKey => false;

  @override
  String? getGeminiApiKey() => null;

  @override
  Future<void> setGeminiApiKey(String? key) async {}

  @override
  Future<Result<SmartTaskDraft>> parseTaskPrompt(
    String prompt, {
    DateTime? referenceTime,
    List<String>? availableCategories,
  }) async {
    return Success(
      SmartTaskDraft(
        name: 'Parsed: $prompt',
        priorityIndex: 1,
        subtasks: const ['Subtask 1'],
      ),
    );
  }
}

void main() {
  group('Feature 1: Voice Input & Speech-to-Text Tests', () {
    late FakeSpeechRepo fakeRepo;
    late FakeSmartTaskParser fakeParser;

    setUp(() {
      fakeRepo = FakeSpeechRepo();
      fakeParser = FakeSmartTaskParser();
    });

    test(
      'ProcessVoiceTaskUseCase parses raw transcript into SmartTaskDraft',
      () async {
        final useCase = ProcessVoiceTaskUseCase(nlpParser: fakeParser);

        final result = await useCase('купить молоко и хлеб');

        expect(result, isA<Success<SmartTaskDraft>>());
        final success = result as Success<SmartTaskDraft>;
        expect(success.data.name, 'Parsed: купить молоко и хлеб');
        expect(success.data.subtasks, contains('Subtask 1'));
      },
    );

    test(
      'ProcessVoiceTaskUseCase returns error when transcript is empty',
      () async {
        final useCase = ProcessVoiceTaskUseCase(nlpParser: fakeParser);

        final result = await useCase('   ');

        expect(result, isA<Error<SmartTaskDraft>>());
        final error = result as Error<SmartTaskDraft>;
        expect(error.failure, isA<ServerFailure>());
      },
    );

    test(
      'VoiceTaskController initializes and captures speech events',
      () async {
        final initUseCase = InitializeSpeechUseCase(fakeRepo);
        final startUseCase = StartListeningUseCase(fakeRepo);
        final stopUseCase = StopListeningUseCase(fakeRepo);
        final processUseCase = ProcessVoiceTaskUseCase(nlpParser: fakeParser);

        final controller = VoiceTaskController(
          initializeUseCase: initUseCase,
          startListeningUseCase: startUseCase,
          stopListeningUseCase: stopUseCase,
          processVoiceTaskUseCase: processUseCase,
        );

        expect(controller.status, VoiceTaskStatus.idle);

        // Start listening
        await controller.startListening();
        expect(controller.status, VoiceTaskStatus.listening);
        expect(fakeRepo.isListening, isTrue);

        // Emit intermediate result
        fakeRepo.emitResult(
          const SpeechRecognitionResult(
            recognizedWords: 'купить продуктов',
            confidence: 0.9,
            soundLevelDb: -12.0,
            isFinal: false,
          ),
        );

        // Wait a microtask
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(controller.transcript, 'купить продуктов');
        expect(controller.soundLevelDb, -12.0);

        // Stop listening manually via stopAndProcess
        await controller.stopAndProcess();
        expect(controller.status, VoiceTaskStatus.completed);
        expect(controller.draft?.name, 'Parsed: купить продуктов');
        expect(fakeRepo.isListening, isFalse);

        controller.dispose();
      },
    );

    test('VoiceTaskController auto-processes final speech result', () async {
      final initUseCase = InitializeSpeechUseCase(fakeRepo);
      final startUseCase = StartListeningUseCase(fakeRepo);
      final stopUseCase = StopListeningUseCase(fakeRepo);
      final processUseCase = ProcessVoiceTaskUseCase(nlpParser: fakeParser);

      final controller = VoiceTaskController(
        initializeUseCase: initUseCase,
        startListeningUseCase: startUseCase,
        stopListeningUseCase: stopUseCase,
        processVoiceTaskUseCase: processUseCase,
      );

      await controller.startListening();

      // Emit final result
      fakeRepo.emitResult(
        const SpeechRecognitionResult(
          recognizedWords: 'записаться к врачу',
          confidence: 0.95,
          soundLevelDb: -5.0,
          isFinal: true,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(controller.status, VoiceTaskStatus.completed);
      expect(controller.draft, isNotNull);
      expect(controller.draft?.name, 'Parsed: записаться к врачу');

      controller.dispose();
    });
  });
}
