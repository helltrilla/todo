import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/digest/domain/entities/daily_digest.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

abstract interface class IDailyDigestRemoteDataSource {
  Future<DailyDigest?> generateDigest({
    required List<Task> tasks,
    DateTime? referenceTime,
  });
}

class DailyDigestRemoteDataSource implements IDailyDigestRemoteDataSource {
  final http.Client _client;
  final SharedPreferences _prefs;

  DailyDigestRemoteDataSource({
    http.Client? client,
    required SharedPreferences prefs,
  })  : _client = client ?? http.Client(),
        _prefs = prefs;

  static const _prefApiKey = 'gemini_api_key_v1';
  static const _geminiModel = 'gemini-2.0-flash';

  String? _getApiKey() {
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
  Future<DailyDigest?> generateDigest({
    required List<Task> tasks,
    DateTime? referenceTime,
  }) async {
    final apiKey = _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final now = referenceTime ?? DateTime.now();
    final pending = tasks.where((t) => !t.isCompleted && !t.isArchived).toList();
    if (pending.isEmpty) {
      return null;
    }

    final taskSummaries = pending.take(15).map((t) {
      final dueStr = t.dueDate != null ? 'Дедлайн: ${t.dueDate!.toIso8601String()}' : 'Без дедлайна';
      final prioStr = switch (t.priorityIndex) {
        0 => 'P1 (Срочно)',
        1 => 'P2 (Высокий)',
        2 => 'P3 (Средний)',
        _ => 'P4 (Низкий)',
      };
      return '- "${t.name}" [Категория: ${t.category}, Приоритет: $prioStr, $dueStr]';
    }).join('\n');

    final systemInstruction = '''
Ты — элитный персональный executive-ассистент и коуч по продуктивности.
Твоя задача — проанализировать список задач пользователя на сегодня и составить вдохновляющий, емкий утренний дайджест.
Текущее время: ${now.toIso8601String()}.

Правила:
1. Выдели ровно одну ключевую задачу дня ("topFocus").
2. Порекомендуй лучший временной слот ("productivitySlot"), например "10:00 – 12:30 (утренний пик энергии)" или "14:00 – 16:00 (глубокий фокус)".
3. Напиши заголовок ("headline") до 6-8 слов на русском языке.
4. Напиши "summary" ровно в 2-3 энергичных предложения на русском языке с четким планом действий.

Ответь СТРОГО в формате JSON со следующими полями:
{
  "headline": "...",
  "topFocus": "...",
  "productivitySlot": "...",
  "summary": "..."
}
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': '$systemInstruction\n\nЗадачи пользователя на сегодня:\n$taskSummaries',
            },
          ],
        },
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.2,
      },
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.warning('Gemini DailyDigest returned ${response.statusCode}');
        return null;
      }

      final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = bodyJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) return null;

      final parsed = jsonDecode(text) as Map<String, dynamic>;
      return DailyDigest(
        headline: (parsed['headline'] as String?) ?? 'Утренний бриф от ИИ',
        topFocus: (parsed['topFocus'] as String?) ?? pending.first.name,
        productivitySlot: (parsed['productivitySlot'] as String?) ?? '10:00 – 12:30',
        summary: (parsed['summary'] as String?) ?? '',
        generatedAt: now,
        isFallback: false,
      );
    } catch (e, st) {
      AppLogger.warning('DailyDigestRemoteDataSource failed to generate digest', e, st);
      return null;
    }
  }
}
