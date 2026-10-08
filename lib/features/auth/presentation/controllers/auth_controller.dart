import 'package:flutter/foundation.dart';
import 'package:todo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';

/// Application-layer controller for authentication state.
/// Coordinates between Auth UI, GoRouter redirects, and [IAuthRepository].
class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    _currentUser = _repository.getCurrentUser();
  }

  final IAuthRepository _repository;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> registerInternal({
    required String name,
    required String login,
    required String password,
  }) async {
    return _runAuthAction(() async {
      _currentUser = await _repository.registerInternal(
        name: name,
        login: login,
        password: password,
      );
    });
  }

  Future<bool> signInInternal({
    required String login,
    required String password,
  }) async {
    return _runAuthAction(() async {
      _currentUser = await _repository.signInInternal(
        login: login,
        password: password,
      );
    });
  }

  Future<bool> sendEmailOtp({required String email, String? name}) async {
    return _runAuthAction(() async {
      await _repository.sendEmailOtp(email: email, name: name);
    });
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    return _runAuthAction(() async {
      _currentUser = await _repository.verifyEmailOtp(
        email: email,
        code: code,
        name: name,
      );
    });
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Ошибка соединения: проверьте интернет или настройки';
      debugPrint('AuthController error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
