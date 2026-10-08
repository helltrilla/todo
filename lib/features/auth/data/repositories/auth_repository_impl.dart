import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/config/app_config.dart';
import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';

/// Implementation of [IAuthRepository] combining:
/// 1. Local internal registration & login via [SharedPreferences].
/// 2. Real Email OTP authentication via Supabase Auth REST API.
///
/// Wraps all results in [Result<T>] with strongly typed [Failure]s.
class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl(this._prefs, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _http;

  static const _currentUserKey = 'auth_current_user';
  static const _internalAccountsKey = 'auth_internal_accounts';

  @override
  AppUser? getCurrentUser() {
    final raw = _prefs.getString(_currentUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<AppUser>> registerInternal({
    required String name,
    required String login,
    required String password,
  }) async {
    try {
      final normalizedLogin = login.trim().toLowerCase();
      final accounts = _loadInternalAccounts();

      if (accounts.containsKey(normalizedLogin)) {
        return const Error(
          AuthFailure('Такой логин уже зарегистрирован локально'),
        );
      }

      final user = AppUser(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: normalizedLogin,
        isLocal: true,
      );

      accounts[normalizedLogin] = <String, dynamic>{
        'password': password,
        'user': user.toMap(),
      };

      await _prefs.setString(_internalAccountsKey, json.encode(accounts));
      await _saveSession(user);
      return Success(user);
    } catch (_) {
      return const Error(CacheFailure('Ошибка сохранения локального профиля'));
    }
  }

  @override
  Future<Result<AppUser>> signInInternal({
    required String login,
    required String password,
  }) async {
    try {
      final normalizedLogin = login.trim().toLowerCase();
      final accounts = _loadInternalAccounts();
      final record = accounts[normalizedLogin];

      if (record == null) {
        return const Error(
          AuthFailure('Аккаунт не найден. Зарегистрируйтесь!'),
        );
      }

      if (record['password'] != password) {
        return const Error(AuthFailure('Неверный пароль'));
      }

      final user = AppUser.fromMap(record['user'] as Map<String, dynamic>);
      await _saveSession(user);
      return Success(user);
    } catch (_) {
      return const Error(CacheFailure('Ошибка чтения локального профиля'));
    }
  }

  @override
  Future<Result<void>> sendEmailOtp({
    required String email,
    String? name,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/auth/v1/otp');
      final body = <String, dynamic>{
        'email': email.trim(),
        'create_user': true,
        if (name != null && name.trim().isNotEmpty)
          'data': <String, dynamic>{'name': name.trim()},
      };

      final response = await _http
          .post(uri, headers: _supabaseHeaders, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Error(ServerFailure(_extractSupabaseError(response.body)));
      }
      return const Success(null);
    } on TimeoutException {
      return const Error(
        NetworkFailure('Превышено время ожидания ответа от сервера'),
      );
    } catch (_) {
      return const Error(
        NetworkFailure('Ошибка сети: проверьте подключение к интернету'),
      );
    }
  }

  @override
  Future<Result<AppUser>> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanCode = code.trim();

      var response = await _verifyWithType(
        email: cleanEmail,
        token: cleanCode,
        type: 'email',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final fallbackResponse = await _verifyWithType(
          email: cleanEmail,
          token: cleanCode,
          type: 'signup',
        );
        if (fallbackResponse.statusCode >= 200 &&
            fallbackResponse.statusCode < 300) {
          response = fallbackResponse;
        } else {
          return Error(ServerFailure(_extractSupabaseError(response.body)));
        }
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final userMap =
          (decoded['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final metadata =
          (userMap['user_metadata'] as Map<String, dynamic>?) ??
          <String, dynamic>{};

      final resolvedName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (metadata['name'] as String?) ?? cleanEmail.split('@').first;

      final user = AppUser(
        id: (userMap['id'] as String?) ?? 'sb_${cleanEmail.hashCode}',
        name: resolvedName,
        email: cleanEmail,
        isLocal: false,
      );

      await _saveSession(user);
      return Success(user);
    } on TimeoutException {
      return const Error(
        NetworkFailure('Превышено время ожидания ответа от сервера'),
      );
    } catch (_) {
      return const Error(
        NetworkFailure('Ошибка сети при проверке кода подтверждения'),
      );
    }
  }

  @override
  Future<Result<AppUser>> updateDisplayName(String newName) async {
    try {
      final current = getCurrentUser();
      if (current == null) {
        return const Error(AuthFailure('Пользователь не авторизован'));
      }

      final cleanName = newName.trim();
      if (cleanName.isEmpty) {
        return const Error(AuthFailure('Имя не может быть пустым'));
      }

      final updated = AppUser(
        id: current.id,
        name: cleanName,
        email: current.email,
        isLocal: current.isLocal,
      );

      if (current.isLocal && current.email != null) {
        final accounts = _loadInternalAccounts();
        final key = current.email!.toLowerCase();
        if (accounts.containsKey(key)) {
          final record = Map<String, dynamic>.from(
            accounts[key] as Map<String, dynamic>,
          );
          record['user'] = updated.toMap();
          accounts[key] = record;
          await _prefs.setString(_internalAccountsKey, json.encode(accounts));
        }
      }

      await _saveSession(updated);
      return Success(updated);
    } catch (_) {
      return const Error(CacheFailure('Не удалось обновить имя профиля'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _prefs.remove(_currentUserKey);
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('Не удалось выйти из профиля'));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<http.Response> _verifyWithType({
    required String email,
    required String token,
    required String type,
  }) {
    final uri = Uri.parse('${AppConfig.supabaseUrl}/auth/v1/verify');
    return _http
        .post(
          uri,
          headers: _supabaseHeaders,
          body: json.encode(<String, dynamic>{
            'email': email,
            'token': token,
            'type': type,
          }),
        )
        .timeout(const Duration(seconds: 15));
  }

  Map<String, String> get _supabaseHeaders => <String, String>{
    'apikey': AppConfig.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
    'Content-Type': 'application/json',
  };

  String _extractSupabaseError(String responseBody) {
    try {
      final map = json.decode(responseBody) as Map<String, dynamic>;
      final msg =
          map['msg'] ??
          map['message'] ??
          map['error_description'] ??
          map['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'Ошибка авторизации Supabase. Проверьте данные или код.';
  }

  Map<String, dynamic> _loadInternalAccounts() {
    final raw = _prefs.getString(_internalAccountsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _saveSession(AppUser user) async {
    await _prefs.setString(_currentUserKey, user.toJson());
  }
}
