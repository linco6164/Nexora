import 'package:flutter/foundation.dart';

import '../api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  bool _loading = false;

  Map<String, dynamic>? get user => _user;

  bool get loading => _loading;

  bool get isLoggedIn => _user != null;

  Future<void> loadUser() async {
    try {
      _user = await ApiService.getCurrentUser();
    } catch (_) {
      _user = null;
    }

    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      await ApiService.login(
        email: email,
        password: password,
      );

      _user = await ApiService.getCurrentUser();

      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      await ApiService.register(
        username: username,
        email: email,
        password: password,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();

    _user = null;

    notifyListeners();
  }
}