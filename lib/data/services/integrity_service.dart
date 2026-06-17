import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IntegrityService {
  static const _channel = MethodChannel('com.example.app_demo/integrity');

  static Future<bool> isFridaDetected() async {
    if (kDebugMode) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isFridaDetected');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isRootDetected() async {
    if (kDebugMode) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isRootDetected');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isIntegrityCompromised() async {
    if (kDebugMode) return false;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isIntegrityCompromised');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
