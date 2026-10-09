import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/voice/domain/entities/speech_recognition_result.dart';
import 'package:todo/features/voice/domain/usecases/initialize_speech_use_case.dart';
import 'package:todo/features/voice/domain/usecases/process_voice_task_use_case.dart';
import 'package:todo/features/voice/domain/usecases/start_listening_use_case.dart';
import 'package:todo/features/voice/domain/usecases/stop_listening_use_case.dart';

enum VoiceTaskStatus {
  idle,
  initializing,
  listening,
  processingNlp,
  completed,
  error,
}

class VoiceTaskController extends ChangeNotifier {
  VoiceTaskController({
    required InitializeSpeechUseCase initializeUseCase,
    required StartListeningUseCase startListeningUseCase,
    required StopListeningUseCase stopListeningUseCase,
    required ProcessVoiceTaskUseCase processVoiceTaskUseCase,
  }) : _initializeUseCase = initializeUseCase,
       _startListeningUseCase = startListeningUseCase,
       _stopListeningUseCase = stopListeningUseCase,
       _processVoiceTaskUseCase = processVoiceTaskUseCase;

  final InitializeSpeechUseCase _initializeUseCase;
  final StartListeningUseCase _startListeningUseCase;
  final StopListeningUseCase _stopListeningUseCase;
  final ProcessVoiceTaskUseCase _processVoiceTaskUseCase;

  VoiceTaskStatus _status = VoiceTaskStatus.idle;
  String _transcript = '';
  double _soundLevelDb = 0.0;
  SmartTaskDraft? _draft;
  String? _errorMessage;

  StreamSubscription<Result<SpeechRecognitionResult>>? _listeningSubscription;
  Timer? _silenceWatchdog;

  VoiceTaskStatus get status => _status;
  String get transcript => _transcript;
  double get soundLevelDb => _soundLevelDb;
  SmartTaskDraft? get draft => _draft;
  String? get errorMessage => _errorMessage;

  bool get isListening => _status == VoiceTaskStatus.listening;
  bool get isProcessing => _status == VoiceTaskStatus.processingNlp;

  Future<void> startListening({
    List<String>? availableCategories,
    String localeId = 'ru_RU',
  }) async {
    _status = VoiceTaskStatus.initializing;
    _errorMessage = null;
    _transcript = '';
    _draft = null;
    notifyListeners();

    final initResult = await _initializeUseCase();
    if (initResult is Error<bool> ||
        (initResult is Success<bool> && !initResult.data)) {
      _status = VoiceTaskStatus.error;
      _errorMessage = initResult is Error<bool>
          ? initResult.failure.message
          : 'Доступ к микрофону не предоставлен. Разрешите его в настройках телефона.';
      notifyListeners();
      return;
    }

    _status = VoiceTaskStatus.listening;
    notifyListeners();

    _listeningSubscription?.cancel();
    _listeningSubscription = _startListeningUseCase(localeId: localeId).listen(
      (result) async {
        if (result is Success<SpeechRecognitionResult>) {
          final data = result.data;
          _transcript = data.recognizedWords;
          _soundLevelDb = data.soundLevelDb;
          notifyListeners();

          _restartSilenceWatchdog(availableCategories);

          if (data.isFinal) {
            await stopAndProcess(availableCategories: availableCategories);
          }
        } else if (result is Error<SpeechRecognitionResult>) {
          _status = VoiceTaskStatus.error;
          _errorMessage = result.failure.message;
          notifyListeners();
        }
      },
      onError: (err) {
        _status = VoiceTaskStatus.error;
        _errorMessage = 'Ошибка аудиопотока: $err';
        notifyListeners();
      },
    );
  }

  void _restartSilenceWatchdog(List<String>? availableCategories) {
    _silenceWatchdog?.cancel();
    // 2.8 seconds of silence after spoken text triggers automated finalization
    _silenceWatchdog = Timer(const Duration(milliseconds: 2800), () {
      if (_transcript.trim().isNotEmpty &&
          _status == VoiceTaskStatus.listening) {
        stopAndProcess(availableCategories: availableCategories);
      }
    });
  }

  Future<void> stopAndProcess({List<String>? availableCategories}) async {
    _silenceWatchdog?.cancel();
    await _stopListeningUseCase();
    await _listeningSubscription?.cancel();

    final text = _transcript.trim();
    if (text.isEmpty) {
      _status = VoiceTaskStatus.idle;
      notifyListeners();
      return;
    }

    _status = VoiceTaskStatus.processingNlp;
    notifyListeners();

    final parseResult = await _processVoiceTaskUseCase(
      text,
      availableCategories: availableCategories,
    );

    if (parseResult is Success<SmartTaskDraft>) {
      _draft = parseResult.data;
      _status = VoiceTaskStatus.completed;
      notifyListeners();
    } else if (parseResult is Error<SmartTaskDraft>) {
      _status = VoiceTaskStatus.error;
      _errorMessage = parseResult.failure.message;
      notifyListeners();
    }
  }

  void cancel() {
    _silenceWatchdog?.cancel();
    _listeningSubscription?.cancel();
    _stopListeningUseCase();
    _status = VoiceTaskStatus.idle;
    _transcript = '';
    _draft = null;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _status = VoiceTaskStatus.idle;
    _transcript = '';
    _draft = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _silenceWatchdog?.cancel();
    _listeningSubscription?.cancel();
    super.dispose();
  }
}
