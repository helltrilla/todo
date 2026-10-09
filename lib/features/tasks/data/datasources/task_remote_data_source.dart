import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/domain/models/task.dart';

/// Contract for interacting directly with Supabase PostgREST API for Tasks.
abstract interface class ITaskRemoteDataSource {
  Future<Result<List<Task>>> fetchTasks({
    required String userId,
    required String accessToken,
  });

  Future<Result<Task>> upsertTask({
    required Task task,
    required String userId,
    required String accessToken,
  });

  Future<Result<void>> upsertAllTasks({
    required List<Task> tasks,
    required String userId,
    required String accessToken,
  });

  Future<Result<void>> deleteTask({
    required int id,
    required String accessToken,
  });

  Future<Result<void>> deleteCompletedTasks({
    required String userId,
    required String accessToken,
  });
}

/// HTTP implementation of [ITaskRemoteDataSource] communicating with Supabase.
class SupabaseTaskRemoteDataSource implements ITaskRemoteDataSource {
  SupabaseTaskRemoteDataSource({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  Map<String, String> _buildHeaders(String accessToken, {String? prefer}) {
    final headers = <String, String>{
      'apikey': AppConfig.supabaseAnonKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    if (prefer != null) {
      headers['Prefer'] = prefer;
    }
    return headers;
  }

  @override
  Future<Result<List<Task>>> fetchTasks({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/tasks?user_id=eq.$userId&order=created_at.desc',
      );
      final response = await _http
          .get(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (json.decode(response.body) as List<dynamic>)
            .map((item) => Task.fromSupabaseMap(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }

      return Error(
        ServerFailure(_parseError(response.body, response.statusCode)),
      );
    } on TimeoutException {
      return const Error(
        NetworkFailure('Время ожидания запроса к облаку истекло'),
      );
    } catch (e) {
      return Error(
        NetworkFailure('Ошибка сети при загрузке задач из облака: $e'),
      );
    }
  }

  @override
  Future<Result<Task>> upsertTask({
    required Task task,
    required String userId,
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/tasks');
      final body = json.encode(task.toSupabaseMap(userId));
      final response = await _http
          .post(
            uri,
            headers: _buildHeaders(
              accessToken,
              prefer: 'resolution=merge-duplicates,return=representation',
            ),
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return Success(
            Task.fromSupabaseMap(decoded.first as Map<String, dynamic>),
          );
        }
        return Success(task);
      }

      return Error(
        ServerFailure(_parseError(response.body, response.statusCode)),
      );
    } on TimeoutException {
      return const Error(
        NetworkFailure('Таймаут синхронизации задачи с облаком'),
      );
    } catch (e) {
      return Error(
        NetworkFailure('Ошибка сети при сохранении задачи в облако: $e'),
      );
    }
  }

  @override
  Future<Result<void>> upsertAllTasks({
    required List<Task> tasks,
    required String userId,
    required String accessToken,
  }) async {
    if (tasks.isEmpty) return const Success(null);
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/tasks');
      final body = json.encode(
        tasks.map((t) => t.toSupabaseMap(userId)).toList(),
      );
      final response = await _http
          .post(
            uri,
            headers: _buildHeaders(
              accessToken,
              prefer: 'resolution=merge-duplicates',
            ),
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      return Error(
        ServerFailure(_parseError(response.body, response.statusCode)),
      );
    } on TimeoutException {
      return const Error(NetworkFailure('Таймаут выгрузки задач в облако'));
    } catch (e) {
      return Error(
        NetworkFailure('Ошибка сети при пакетной выгрузке задач: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteTask({
    required int id,
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/tasks?id=eq.$id');
      final response = await _http
          .delete(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      return Error(
        ServerFailure(_parseError(response.body, response.statusCode)),
      );
    } on TimeoutException {
      return const Error(NetworkFailure('Таймаут удаления задачи из облака'));
    } catch (e) {
      return Error(NetworkFailure('Ошибка сети при удалении задачи: $e'));
    }
  }

  @override
  Future<Result<void>> deleteCompletedTasks({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/tasks?user_id=eq.$userId&is_completed=eq.true',
      );
      final response = await _http
          .delete(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      return Error(
        ServerFailure(_parseError(response.body, response.statusCode)),
      );
    } on TimeoutException {
      return const Error(
        NetworkFailure('Таймаут очистки выполненных задач в облаке'),
      );
    } catch (e) {
      return Error(
        NetworkFailure('Ошибка сети при очистке выполненных задач: $e'),
      );
    }
  }

  String _parseError(String body, int statusCode) {
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      final msg = map['message'] ?? map['details'] ?? map['hint'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'Ошибка сервера Supabase ($statusCode)';
  }
}
