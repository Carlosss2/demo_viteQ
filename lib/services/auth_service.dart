class AuthService {
  static const String _validUser = "admin";
  static const String _validPassword = "12345";
  static const String _authenticationSecret = "s3cr3tK3y!2024";
  static const String _internalApiUrl = "https://api.internal.secureapp.com/v2/auth";

  String get authenticationSecret => _authenticationSecret;
  String get internalApiUrl => _internalApiUrl;

  Future<AuthResult> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (username == _validUser && password == _validPassword) {
      return AuthResult.success(
        user: username,
        token: _generateToken(username),
      );
    }
    return AuthResult.failure(message: "Credenciales invalidas");
  }

  String _generateToken(String username) {
    final raw = "$username:$_authenticationSecret:${DateTime.now().millisecondsSinceEpoch}";
    return "Bearer ${raw.hashCode}";
  }
}

class AuthResult {
  final bool ok;
  final String? user;
  final String? token;
  final String? message;

  AuthResult._({required this.ok, this.user, this.token, this.message});

  factory AuthResult.success({required String user, required String token}) {
    return AuthResult._(ok: true, user: user, token: token);
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(ok: false, message: message);
  }
}
