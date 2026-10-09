import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/core/logging/app_logger.dart';
import 'package:todo/features/tasks/data/models/task_model.dart';
import 'package:todo/features/tasks/domain/entities/task.dart';

/// Contract for interacting directly with Supabase PostgREST API for Tasks.
abstract interface class ISyncRemoteDataSource {
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

/// Backward compatibility typedef for existing tests and implementations.
typedef ITaskRemoteDataSource = ISyncRemoteDataSource;

/// HTTP implementation of [ISyncRemoteDataSource] communicating with Supabase PostgREST.
class SupabaseTaskRemoteDataSource implements ISyncRemoteDataSource {
  SupabaseTaskRemoteDataSource({
    http.Client? httpClient,
    String? supabaseUrl,
    String? supabaseAnonKey,
  })  : _http = httpClient ?? http.Client(),
        _supabaseUrl = supabaseUrl ??
            (AppConfig.supabaseUrl.isNotEmpty
                ? AppConfig.supabaseUrl
                : 'https://api.supabase.co'),
        _supabaseAnonKey = supabaseAnonKey ?? AppConfig.supabaseAnonKey;

  final http.Client _http;
  final String _supabaseUrl;
  final String _supabaseAnonKey;

  Map<String, String> _buildHeaders(String accessToken, {String? prefer}) {
    final headers = <String, String>{
      'apikey': _supabaseAnonKey,
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
        '$_supabaseUrl/rest/v1/tasks?user_id=eq.$userId&order=created_at.desc',
      );
      final response = await _http
          .get(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (json.decode(response.body) as List<dynamic>)
            .map((item) => TaskModel.fromSupabaseMap(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }

      final errorMsg = _parseError(response.body, response.statusCode);
      AppLogger.warning('fetchTasks server failure: $errorMsg');
      return Error(ServerFailure(errorMsg));
    } on TimeoutException catch (e, st) {
      AppLogger.warning('fetchTasks timeout', e, st);
      return const Error(
        NetworkFailure('Время ожидания запроса к облаку истекло'),
      );
    } on SocketException catch (e, st) {
      AppLogger.warning('fetchTasks socket exception', e, st);
      return Error(NetworkFailure('Отсутствует подключение к сети: $e'));
    } catch (e, st) {
      AppLogger.error('fetchTasks unexpected error', e, st);
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
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tasks');
      final model = TaskModel.fromEntity(task);
      final body = json.encode(model.toSupabaseMap(userId));
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
            TaskModel.fromSupabaseMap(decoded.first as Map<String, dynamic>),
          );
        }
        return Success(task);
      }

      final errorMsg = _parseError(response.body, response.statusCode);
      AppLogger.warning('upsertTask server failure: $errorMsg');
      return Error(ServerFailure(errorMsg));
    } on TimeoutException catch (e, st) {
      AppLogger.warning('upsertTask timeout', e, st);
      return const Error(
        NetworkFailure('Таймаут синхронизации задачи с облаком'),
      );
    } on SocketException catch (e, st) {
      AppLogger.warning('upsertTask socket exception', e, st);
      return Error(NetworkFailure('Отсутствует подключение к сети: $e'));
    } catch (e, st) {
      AppLogger.error('upsertTask unexpected error', e, st);
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
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tasks');
      final body = json.encode(
        tasks.map((t) => TaskModel.fromEntity(t).toSupabaseMap(userId)).toList(),
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

      final errorMsg = _parseError(response.body, response.statusCode);
      AppLogger.warning('upsertAllTasks server failure: $errorMsg');
      return Error(ServerFailure(errorMsg));
    } on TimeoutException catch (e, st) {
      AppLogger.warning('upsertAllTasks timeout', e, st);
      return const Error(NetworkFailure('Таймаут выгрузки задач в облако'));
    } on SocketException catch (e, st) {
      AppLogger.warning('upsertAllTasks socket exception', e, st);
      return Error(NetworkFailure('Отсутствует подключение к сети: $e'));
    } catch (e, st) {
      AppLogger.error('upsertAllTasks unexpected error', e, st);
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
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tasks?id=eq.$id');
      final response = await _http
          .delete(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      final errorMsg = _parseError(response.body, response.statusCode);
      AppLogger.warning('deleteTask server failure: $errorMsg');
      return Error(ServerFailure(errorMsg));
    } on TimeoutException catch (e, st) {
      AppLogger.warning('deleteTask timeout', e, st);
      return const Error(NetworkFailure('Таймаут удаления задачи из облака'));
    } on SocketException catch (e, st) {
      AppLogger.warning('deleteTask socket exception', e, st);
      return Error(NetworkFailure('Отсутствует подключение к сети: $e'));
    } catch (e, st) {
      AppLogger.error('deleteTask unexpected error', e, st);
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
        '$_supabaseUrl/rest/v1/tasks?user_id=eq.$userId&is_completed=eq.true',
      );
      final response = await _http
          .delete(uri, headers: _buildHeaders(accessToken))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      final errorMsg = _parseError(response.body, response.statusCode);
      AppLogger.warning('deleteCompletedTasks server failure: $errorMsg');
      return Error(ServerFailure(errorMsg));
    } on TimeoutException catch (e, st) {
      AppLogger.warning('deleteCompletedTasks timeout', e, st);
      return const Error(
        NetworkFailure('Таймаут очистки выполненных задач в облаке'),
      );
    } on SocketException catch (e, st) {
      AppLogger.warning('deleteCompletedTasks socket exception', e, st);
      return Error(NetworkFailure('Отсутствует подключение к сети: $e'));
    } catch (e, st) {
      AppLogger.error('deleteCompletedTasks unexpected error', e, st);
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
    } catch (e, st) {
      AppLogger.debug('Failed to parse Supabase error response body: $e\n$st');
    }
    return 'Ошибка сервера Supabase ($statusCode)';
  }
}
