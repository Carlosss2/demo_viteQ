import '../models/user_model.dart';

class AuthService {
  // Simulamos una base de datos local / API con credenciales fijas
  final String _mockUser = "admin";
  final String _mockPassword = "123";

  /// Simula la petición HTTP a un backend con un retraso de 2 segundos.
  Future<UserModel> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (username == _mockUser && password == _mockPassword) {
      return UserModel(
        id: "usr_999",
        username: "admin",
        email: "admin@arquitecturalimpia.com",
      );
    } else {
      // Lanzamos una excepción genérica si las credenciales fallan
      throw Exception("Usuario o contraseña incorrectos");
    }
  }
}