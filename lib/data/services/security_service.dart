import 'package:detect_fake_location/detect_fake_location.dart';

class SecurityService {
  /// Evalúa si el entorno del dispositivo está usando un Fake GPS.
  Future<bool> isFakeGpsDetected() async {
    try {
      // detect_fake_location cuenta con soporte nativo completo para Android e iOS
      bool isFake = await DetectFakeLocation().detectFakeLocation();
      return isFake;
    } catch (e) {
      // Si falla por falta de permisos o configuración, devolvemos false por estabilidad
      return false;
    }
  }
}