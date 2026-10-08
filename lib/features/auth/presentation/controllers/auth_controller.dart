import 'package:flutter/foundation.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/auth/domain/models/app_user.dart';
import 'package:todo/features/auth/domain/repositories/i_auth_repository.dart';

/// Application-layer controller for authentication state.
///
/// Uses functional [Result<T>] pattern matching without generic try/catch
/// in the presentation layer, strictly adhering to AGENTS.md & ARCHITECTURE.md.
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
    _startLoading();
    final result = await _repository.registerInternal(
      name: name,
      login: login,
      password: password,
    );
    return _handleUserResult(result);
  }

  Future<bool> signInInternal({
    required String login,
    required String password,
  }) async {
    _startLoading();
    final result = await _repository.signInInternal(
      login: login,
      password: password,
    );
    return _handleUserResult(result);
  }

  Future<bool> sendEmailOtp({required String email, String? name}) async {
    _startLoading();
    final result = await _repository.sendEmailOtp(email: email, name: name);
    _isLoading = false;

    switch (result) {
      case Success():
        notifyListeners();
        return true;
      case Error(:final failure):
        _error = failure.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    _startLoading();
    final result = await _repository.verifyEmailOtp(
      email: email,
      code: code,
      name: name,
    );
    return _handleUserResult(result);
  }

  Future<bool> updateDisplayName(String newName) async {
    _startLoading();
    final result = await _repository.updateDisplayName(newName);
    return _handleUserResult(result);
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

  void _startLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  bool _handleUserResult(Result<AppUser> result) {
    _isLoading = false;
    switch (result) {
      case Success(:final data):
        _currentUser = data;
        notifyListeners();
        return true;
      case Error(:final failure):
        _error = failure.message;
        notifyListeners();
        return false;
    }
  }
}
