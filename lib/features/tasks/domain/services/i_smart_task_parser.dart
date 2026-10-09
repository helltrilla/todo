import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';

abstract class ISmartTaskParser {
  /// Parses continuous natural language text into a structured [SmartTaskDraft].
  ///
  /// Takes [prompt] from the user, optional [referenceTime] (defaults to `DateTime.now()`),
  /// and optional [availableCategories] to align categorization with user preferences.
  Future<Result<SmartTaskDraft>> parseTaskPrompt(
    String prompt, {
    DateTime? referenceTime,
    List<String>? availableCategories,
  });

  /// Returns whether a custom Gemini API key is configured.
  bool get hasGeminiApiKey;

  /// Saves or clears the Gemini API key.
  Future<void> setGeminiApiKey(String? key);

  /// Retrieves the currently configured Gemini API key (or null).
  String? getGeminiApiKey();
}
