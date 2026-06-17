# Reporte 2 — Implementación de Borrado Remoto vía FCM

## Objetivo

Implementar una característica de **borrado remoto de datos sensibles** utilizando **Firebase Cloud Messaging (FCM)**. Cuando un mensaje FCM con `action: "REMOTE_WIPE"` es enviado al dispositivo, todos los datos almacenados en `FlutterSecureStorage` son eliminados de forma irreversible.

---

## Archivos creados/modificados

### 1. `lib/data/services/secure_storage_service.dart` **(nuevo)**

Servicio singleton que encapsula el acceso a `FlutterSecureStorage` para 4 campos sensibles:

| Campo               | Key                   |
|----------------------|-----------------------|
| Matrícula           | `matricula`          |
| Contraseña          | `password`           |
| Nombre              | `nombre`             |
| Correo institucional | `correo_institucional` |

**Métodos principales:**

- `saveXxx()` / `getXxx()` — métodos individuales por campo
- `populateDummyData()` — asigna valores de prueba a los 4 campos en paralelo (`Future.wait`)
- `clearAllSensitiveData()` — elimina los 4 campos mediante `Future.wait`
- `readAll()` — devuelve un `Map<String, String?>` con el estado completo

### 2. `lib/main.dart` **(modificado)**

Punto de entrada de la aplicación. Se actualizó para incluir:

**Inicialización de Firebase:**
```dart
await Firebase.initializeApp();
```

**Background handler:**
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['action'] == 'REMOTE_WIPE') {
    final storage = SecureStorageService();
    await storage.clearAllSensitiveData();
  }
}
```
- El `@pragma('vm:entry-point')` evita que el compilador AOT elimine esta función
- Se ejecuta en un **isolate separado** sin acceso a contexto de Flutter
- Se registra con `FirebaseMessaging.onBackgroundMessage()` antes de configurar listeners

**Foreground listener:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['action'] == 'REMOTE_WIPE') {
    SecureStorageService().clearAllSensitiveData();
  }
});
```
- Ejecuta el borrado inmediato cuando la app está activa

**Obtención del FCM Token:**
```dart
final fcmToken = await FirebaseMessaging.instance.getToken();
debugPrint('FCM Token: $fcmToken');
```
- El token se imprime en consola para poder enviar mensajes dirigidos desde la consola de Firebase o mediante una API externa

**Ciclo de vida del mensaje FCM:**

```
Envío FCM (action: REMOTE_WIPE)
        │
        ├── App en 2º plano → onBackgroundMessage() → isolate separado
        │                           │
        │                    Firebase.initializeApp()
        │                           │
        │                   clearAllSensitiveData()
        │
        └── App en 1er plano → onMessage.listen() → mismo isolate
                                │
                        clearAllSensitiveData()
```

### 3. `lib/views/secure_storage_home.dart` **(nuevo)**

Pantalla de prueba que permite validar visualmente el funcionamiento del borrado remoto.

**Componentes:**

| Elemento               | Función                                              |
|------------------------|------------------------------------------------------|
| Botón "Generar Datos"  | Llama a `populateDummyData()` y refresca la UI      |
| Botón "Refrescar"      | Recarga el estado actual desde secure storage        |
| 4 Cards informativas   | Muestran el valor de cada campo o **"Vacío"** si fue borrado. Icono verde si existe, rojo si está vacío |

**Estados visuales:**

- **Datos presentes:** Icono verde `check_circle` + valor del campo
- **Datos borrados:** Icono rojo `error_outline` + texto "Vacío"

---

## Dependencias utilizadas

Todas ya estaban declaradas en `pubspec.yaml`:

| Paquete                  | Versión   | Propósito                          |
|--------------------------|-----------|------------------------------------|
| `flutter_secure_storage` | ^9.2.4    | Almacenamiento cifrado de datos    |
| `firebase_core`          | ^4.10.0   | Inicialización de Firebase         |
| `firebase_messaging`     | ^16.3.0   | Recepción de mensajes FCM          |

---

## Verificación

El código fue compilado exitosamente con `dart analyze lib/` sin errores ni advertencias.

Para probar la funcionalidad:

1. Ejecutar la app en un dispositivo/emulador
2. Presionar **"Generar Datos de Prueba"** — los 4 campos aparecen con valores dummy
3. Copiar el FCM Token impreso en consola
4. Enviar un mensaje FCM con `action: "REMOTE_WIPE"` (desde Firebase Console, cURL, o Postman)
5. Presionar **"Refrescar"** — los 4 campos deben mostrar **"Vacío"**

Ejemplo de cURL para enviar el mensaje FCM:
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=TU_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_DEL_DISPOSITIVO",
    "data": {
      "action": "REMOTE_WIPE"
    }
  }'
```
