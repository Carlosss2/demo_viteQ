import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FakeGpsService {
  static const _channel = MethodChannel('com.example.app_demo/fake_gps');

  static Future<bool> isMockLocationEnabled() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isMockLocationEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('FakeGpsService error: $e');
      return false;
    }
  }
}
