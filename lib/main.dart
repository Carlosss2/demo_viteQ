import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'data/services/secure_storage_service.dart';
import 'views/secure_storage_home.dart';

/// Handler global para notificaciones FCM en segundo plano.
/// Necesita @pragma('vm:entry-point') para que Dart VM no lo elimine en compilación AOT.
/// Cuando el sistema operativo entrega un RemoteMessage y la app no está en primer plano,
/// este callback se invoca en un isolate separado. Dentro de él NO se puede usar
/// contexto de Flutter (BuildContext, navegación, etc.), solo lógica Dart pura.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Verificar si la acción del mensaje es un borrado remoto
  if (message.data['action'] == 'REMOTE_WIPE') {
    final storage = SecureStorageService();
    await storage.clearAllSensitiveData();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (requerido antes de cualquier llamada a Firebase)
  await Firebase.initializeApp();

  // Registrar el handler de segundo plano antes de configurar los listeners en primer plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Obtener y mostrar el token FCM del dispositivo para pruebas dirigidas
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM Token: $fcmToken');

  // Listener para cuando la app está en primer plano (muestra notificación local si se desea)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data['action'] == 'REMOTE_WIPE') {
      // También ejecutar borrado inmediato si la app está activa
      SecureStorageService().clearAllSensitiveData();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Demo - Borrado Remoto FCM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const SecureStorageHome(),
    );
  }
}
