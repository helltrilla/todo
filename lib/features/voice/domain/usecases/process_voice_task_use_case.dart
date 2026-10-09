import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';

/// Use case that bridges recorded voice transcript to our intelligent NLP parser engine.
class ProcessVoiceTaskUseCase {
  const ProcessVoiceTaskUseCase({required ISmartTaskParser nlpParser})
    : _nlpParser = nlpParser;

  final ISmartTaskParser _nlpParser;

  Future<Result<SmartTaskDraft>> call(
    String transcript, {
    DateTime? referenceTime,
    List<String>? availableCategories,
  }) async {
    final clean = transcript.trim();
    if (clean.isEmpty) {
      return const Error(
        ServerFailure('Голосовой ввод пуст. Повторите попытку.'),
      );
    }

    return _nlpParser.parseTaskPrompt(
      clean,
      referenceTime: referenceTime ?? DateTime.now(),
      availableCategories: availableCategories,
    );
  }
}
