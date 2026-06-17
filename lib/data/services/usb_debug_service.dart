import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsbDebugService {
  static const _channel = MethodChannel('com.example.app_demo/usb_debug');

  static Future<bool> isUsbDebugEnabled() async {
    if (kDebugMode) {
      return false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _channel.invokeMethod<bool>('isUsbDebugEnabled');
        return result ?? false;
      } catch (e) {
        debugPrint('UsbDebugService error: $e');
        return false;
      }
    }

    return false;
  }
}
