import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estados privados
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  // Getters públicos para que la vista los consuma sin modificarlos directamente
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  /// Ejecuta el proceso de Login y notifica los cambios de estado a la UI
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null; // Limpiamos errores previos

    try {
      _user = await _authService.login(username, password);
      _setLoading(false);
      return true; // Login exitoso
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false; // Login fallido
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Notifica a los widgets escuchando este ViewModel
  }
}