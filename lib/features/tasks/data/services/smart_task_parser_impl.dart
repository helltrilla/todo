import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/data/services/local_nlp_parser.dart';
import 'package:todo/features/tasks/domain/models/smart_task_draft.dart';
import 'package:todo/features/tasks/domain/services/i_smart_task_parser.dart';

class SmartTaskParserImpl implements ISmartTaskParser {
  SmartTaskParserImpl({
    required SharedPreferences prefs,
    http.Client? client,
    LocalNlpParser? localParser,
  })  : _prefs = prefs,
        _client = client ?? http.Client(),
        _localParser = localParser ?? const LocalNlpParser();

  final SharedPreferences _prefs;
  final http.Client _client;
  final LocalNlpParser _localParser;

  static const _prefApiKey = 'gemini_api_key_v1';
  static const _geminiModel = 'gemini-2.0-flash';

  @override
  bool get hasGeminiApiKey {
    final key = getGeminiApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  @override
  String? getGeminiApiKey() {
    final stored = _prefs.getString(_prefApiKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    if (AppConfig.geminiApiKey.isNotEmpty) {
      return AppConfig.geminiApiKey;
    }
    return null;
  }

  @override
  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _prefs.remove(_prefApiKey);
    } else {
      await _prefs.setString(_prefApiKey, key.trim());
    }
  }

  @override
  Future<Result<SmartTaskDraft>> parseTaskPrompt(
    String prompt, {
    DateTime? referenceTime,
    List<String>? availableCategories,
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return Success(const SmartTaskDraft(name: '', source: 'empty'));
    }

    final apiKey = getGeminiApiKey();
    final now = referenceTime ?? DateTime.now();

    // If an API key is configured, attempt cloud LLM parsing first
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final cloudResult = await _callGeminiApi(
          apiKey: apiKey,
          prompt: trimmedPrompt,
          now: now,
          categories: availableCategories ?? const [],
        );
        if (cloudResult != null) {
          return Success(cloudResult);
        }
      } catch (_) {
        // Fallback to local heuristic engine on any network or parsing failure
      }
    }

    // Default & offline fallback: intelligent local rule-based NLP engine
    try {
      final localDraft = _localParser.parse(
        trimmedPrompt,
        referenceTime: now,
        availableCategories: availableCategories,
      );
      return Success(localDraft);
    } catch (e) {
      return Error(ServerFailure('Не удалось разобрать задачу: $e'));
    }
  }

  Future<SmartTaskDraft?> _callGeminiApi({
    required String apiKey,
    required String prompt,
    required DateTime now,
    required List<String> categories,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey',
    );

    final categoriesContext = categories.isNotEmpty
        ? categories.join(', ')
        : 'Работа, Личное, Спорт, Здоровье, Покупки, Учеба, Дом';

    final systemInstruction = '''
You are an intelligent task manager assistant.
Analyze the user's free-form task input and extract a structured task.
Current reference date & time: ${now.toIso8601String()} (Weekday: ${_weekdayName(now.weekday)}).
User's existing task categories: $categoriesContext.

Rules:
1. "name": Concise, clean task title without time or priority fluff (e.g. "Визит к стоматологу", "Купить продукты").
2. "description": Any additional context or remarks that were in the text.
3. "dueDateIso": Exact ISO-8601 timestamp string if date/time is mentioned (e.g. "2026-10-10T15:00:00"). If no time or date mentioned, return null.
4. "reminderOffsetMinutes": 15, 30, or null.
5. "priorityIndex": 0 for Urgent (P1 / 🔥), 1 for High (P2 / ⚡), 2 for Medium (P3 / 📌), 3 for Low (P4 / 🌿), or -1 if no priority specified.
6. "category": Pick the best matching category name from the user's categories or an intuitive short one.
7. "subtasks": An array of checklist action items / subtasks broken down from the prompt (strings).

Return ONLY a valid JSON object matching this schema.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemInstruction\n\nUser task input:\n"$prompt"'},
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      },
    });

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      return null;
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final text = parts.first['text'] as String?;
    if (text == null || text.trim().isEmpty) return null;

    final parsedMap = jsonDecode(text) as Map<String, dynamic>;
    parsedMap['source'] = 'gemini';
    return SmartTaskDraft.fromJson(parsedMap);
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}
