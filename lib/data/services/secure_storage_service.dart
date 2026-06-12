import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _matriculaKey = 'matricula';
  static const _passwordKey = 'password';
  static const _nombreKey = 'nombre';
  static const _correoKey = 'correo_institucional';

  static final SecureStorageService _instance = SecureStorageService._();
  factory SecureStorageService() => _instance;
  SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveMatricula(String value) =>
      _storage.write(key: _matriculaKey, value: value);
  Future<String?> getMatricula() =>
      _storage.read(key: _matriculaKey);

  Future<void> savePassword(String value) =>
      _storage.write(key: _passwordKey, value: value);
  Future<String?> getPassword() =>
      _storage.read(key: _passwordKey);

  Future<void> saveNombre(String value) =>
      _storage.write(key: _nombreKey, value: value);
  Future<String?> getNombre() =>
      _storage.read(key: _nombreKey);

  Future<void> saveCorreoInstitucional(String value) =>
      _storage.write(key: _correoKey, value: value);
  Future<String?> getCorreoInstitucional() =>
      _storage.read(key: _correoKey);

  Future<void> populateDummyData() async {
    await Future.wait([
      saveMatricula('2023112345'),
      savePassword('Passw0rd!2026'),
      saveNombre('Carlos Pérez García'),
      saveCorreoInstitucional('carlos.perez@upchiapas.edu.mx'),
    ]);
  }

  Future<void> clearAllSensitiveData() async {
    await Future.wait([
      _storage.delete(key: _matriculaKey),
      _storage.delete(key: _passwordKey),
      _storage.delete(key: _nombreKey),
      _storage.delete(key: _correoKey),
    ]);
  }

  Future<Map<String, String?>> readAll() async {
    final results = await Future.wait([
      getMatricula(),
      getPassword(),
      getNombre(),
      getCorreoInstitucional(),
    ]);
    return {
      'matricula': results[0],
      'password': results[1],
      'nombre': results[2],
      'correo_institucional': results[3],
    };
  }
}
