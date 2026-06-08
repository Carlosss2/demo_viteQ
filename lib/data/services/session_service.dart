import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class SessionService {
  static const _tokenKey = 'session_token';
  static const _usernameKey = 'session_username';
  static const _lastActivityKey = 'last_activity';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession(String username) async {
    final token = _generateToken();
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _lastActivityKey, value: now);
  }

  Future<Map<String, String?>> getSession() async {
    final token = await _storage.read(key: _tokenKey);
    final username = await _storage.read(key: _usernameKey);
    final lastActivity = await _storage.read(key: _lastActivityKey);
    return {
      'token': token,
      'username': username,
      'lastActivity': lastActivity,
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _lastActivityKey);
  }

  Future<void> updateLastActivity() async {
    await _storage.write(
      key: _lastActivityKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastActivity() async {
    final value = await _storage.read(key: _lastActivityKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
