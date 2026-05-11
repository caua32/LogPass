import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _tipo;
  UserData? _user;
  bool _loading = true;

  String? get token => _token;
  String? get tipo => _tipo;
  UserData? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;

  Future<void> loadSession() async {
    _token = await AuthService.getToken();
    _tipo = await AuthService.getTipo();
    if (_token != null) {
      try {
        final data = await ApiService.getMe(_token!);
        _user = UserData.fromJson(data);
      } catch (_) {
        await _clearLocally();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String senha, String tipo) async {
    final res = await ApiService.login(email, senha, tipo);
    if (res['token'] != null) {
      _token = res['token'] as String;
      _tipo = tipo;
      await AuthService.saveToken(_token!, tipo);
      try {
        final data = await ApiService.getMe(_token!);
        _user = UserData.fromJson(data);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _clearLocally();
    notifyListeners();
  }

  Future<void> _clearLocally() async {
    _token = null;
    _tipo = null;
    _user = null;
    await AuthService.clear();
  }
}
