import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/core/config/supabase_config.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Implementation of [IAuthRepository] combining:
/// 1. Local internal registration & login via [SharedPreferences].
/// 2. Real Email OTP authentication via Supabase Auth REST API.
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
  Future<AppUser> registerInternal({
    required String name,
    required String login,
    required String password,
  }) async {
    final normalizedLogin = login.trim().toLowerCase();
    final accounts = _loadInternalAccounts();

    if (accounts.containsKey(normalizedLogin)) {
      throw const AuthException('Такой логин уже зарегистрирован локально');
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
    return user;
  }

  @override
  Future<AppUser> signInInternal({
    required String login,
    required String password,
  }) async {
    final normalizedLogin = login.trim().toLowerCase();
    final accounts = _loadInternalAccounts();
    final record = accounts[normalizedLogin];

    if (record == null) {
      throw const AuthException('Аккаунт не найден. Зарегистрируйтесь!');
    }

    if (record['password'] != password) {
      throw const AuthException('Неверный пароль');
    }

    final user = AppUser.fromMap(record['user'] as Map<String, dynamic>);
    await _saveSession(user);
    return user;
  }

  @override
  Future<void> sendEmailOtp({required String email, String? name}) async {
    final uri = Uri.parse('${SupabaseConfig.url}/auth/v1/otp');
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
      throw AuthException(_extractSupabaseError(response.body));
    }
  }

  @override
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    final cleanEmail = email.trim();
    final cleanCode = code.trim();

    // Try 'email' OTP verification first; if the user is confirming a brand-new
    // signup token, fallback to 'signup' type if needed.
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
        throw AuthException(_extractSupabaseError(response.body));
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
    return user;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_currentUserKey);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<http.Response> _verifyWithType({
    required String email,
    required String token,
    required String type,
  }) {
    final uri = Uri.parse('${SupabaseConfig.url}/auth/v1/verify');
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
    'apikey': SupabaseConfig.anonKey,
    'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
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
