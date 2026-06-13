import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final isAuthenticated = await _authRepository.signIn(
      email: email,
      password: password,
    );

    if (!isAuthenticated) {
      _errorMessage = 'Email ou mot de passe incorrect.';
    }

    _setLoading(false);
    return isAuthenticated;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required MockAccountType accountType,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final isRegistered = await _authRepository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      accountType: accountType,
    );

    if (!isRegistered) {
      _errorMessage = 'Un compte existe deja avec cet email.';
    }

    _setLoading(false);
    return isRegistered;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
