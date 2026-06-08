# Práctica: Timer de Inactividad con Sesión Encriptada

## Objetivo

Implementar un mecanismo de seguridad que cierre la sesión automáticamente cuando el usuario no interactúe con la aplicación durante 1 minuto. El token de sesión y la variable de tiempo deben almacenarse de forma encriptada.

---

## Arquitectura Implementada

Se agregaron **4 nuevos archivos** y se modificaron **3 archivos existentes**:

```
lib/
├── data/
│   └── services/
│       ├── auth_service.dart            (sin cambios)
│       ├── security_service.dart        (sin cambios)
│       └── session_service.dart         ★ NUEVO
├── viewmodels/
│   ├── login_viewmodel.dart             (sin cambios)
│   └── session_viewmodel.dart           ★ NUEVO
├── views/
│   ├── home_view.dart                   ★ NUEVO
│   ├── login_view.dart                  ✱ MODIFICADO
│   └── widgets/
│       └── inactivity_detector.dart     ★ NUEVO
└── main.dart                            ✱ MODIFICADO
```

---

## 1. `flutter_secure_storage` — Almacenamiento Encriptado

**Dependencia agregada** en `pubspec.yaml`:

```yaml
flutter_secure_storage: ^9.2.4
```

### ¿Qué es?

Es un plugin de Flutter que provee una API para almacenar datos de forma segura usando el cifrado nativo del sistema operativo:

| Plataforma | Mecanismo de cifrado |
|------------|----------------------|
| **Android** | `EncryptedSharedPreferences` (AES-256) envuelto en Android Keystore |
| **iOS** | `Keychain Services` (AES-256) |
| **macOS** | `Keychain Services` |
| **Linux** | `libsecret` |
| **Windows** | `Credential Manager` |

Esto garantiza que el token de sesión y la marca de tiempo no puedan ser leídos por otras aplicaciones ni extraídos desde el sistema de archivos.

---

## 2. `SessionService` — Servicio de Sesión Encriptado

**Archivo:** `lib/data/services/session_service.dart`

### Responsabilidad

Proveer una capa de abstracción sobre `flutter_secure_storage` para manejar tres datos críticos:

1. **`session_token`** — Token aleatorio de 64 caracteres hexadecimales (32 bytes)
2. **`session_username`** — Nombre de usuario para mostrar en la UI
3. **`last_activity`** — Marca de tiempo ISO 8601 de la última interacción

### Generación del Token

```dart
String _generateToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
```

Se usa `Random.secure()` (no `Random()`), que obtiene entropía criptográfica del sistema operativo (`/dev/urandom` en Unix, `CryptGenRandom` en Windows). Esto produce un token de 256 bits — suficiente para resistir ataques de fuerza bruta.

### Métodos expuestos

| Método | Función |
|--------|---------|
| `saveSession(username)` | Genera token + guarda token, username y timestamp encriptados |
| `getSession()` | Recupera los tres valores almacenados |
| `clearSession()` | Elimina los tres valores del almacén seguro |
| `updateLastActivity()` | Actualiza solo la marca de tiempo (sin regenerar el token) |
| `getLastActivity()` | Retorna la última marca de tiempo como `DateTime` |

---

## 3. `SessionViewModel` — Vista-Modelo de Sesión con Timer

**Archivo:** `lib/viewmodels/session_viewmodel.dart`

### Responsabilidad

Gestiona el ciclo de vida completo de la sesión:

- Inicio de sesión (guardar datos encriptados)
- Timer de inactividad (cuenta regresiva de 60 segundos)
- Detección de cambios en el ciclo de vida de la app (background/foreground)
- Cierre de sesión automático o manual

### Clase: `SessionViewModel extends ChangeNotifier with WidgetsBindingObserver`

Usamos `with WidgetsBindingObserver` (un **mixin**) en lugar de `implements`. La diferencia clave:

- **`mixin`**: hereda implementaciones *default* (vacías) de todos los métodos del observer, permitiendo sobreescribir solo los que necesitemos (`didChangeAppLifecycleState`).
- **`implements`**: obliga a implementar *todos* los métodos abstractos, lo que genera código redundante.

Esto es posible porque `WidgetsBindingObserver` es un mixin con cuerpos vacíos por defecto.

### Flujo del Timer de Inactividad

```
Usuario interactúa
       │
       ▼
resetInactivityTimer()
  - reinicia _remainingSeconds = 60
  - guarda timestamp en almacén encriptado
  - reinicia el Timer interno
       │
       ▼
_startInactivityTimer()
  - Timer.periodic(1 segundo)
  - cada tick: _remainingSeconds--
  - si _remainingSeconds <= 0 → logout()
  - si no → notifyListeners() para actualizar UI
```

### Manejo del Ciclo de Vida

Cuando la app pasa a **background** (`paused`):
- Se guarda `updateLastActivity()` inmediatamente.

Cuando la app regresa a **foreground** (`resumed`):
- Se lee la última actividad desde almacén encriptado.
- Se calcula el tiempo transcurrido.
- Si pasaron ≥ 60 segundos → `logout()` automático.
- Si pasaron < 60 segundos → se ajusta el contador (`_remainingSeconds = 60 - elapsed`).

Esto impide que un usuario evite el timeout simplemente minimizando la app.

---

## 4. `InactivityDetector` — Widget Detector de Interacción

**Archivo:** `lib/views/widgets/inactivity_detector.dart`

### Responsabilidad

Escuchar **toda** interacción del usuario con la pantalla (toques, arrastres, clicks) y notificar al `SessionViewModel` para reiniciar el timer.

```dart
Listener(
  onPointerDown: (_) => onActivity(),
  onPointerMove: (_) => onActivity(),
  onPointerUp: (_) => onActivity(),
  onPointerSignal: (_) => onActivity(),
  child: child,
)
```

Usamos `Listener` (no `GestureDetector`) porque:
- **`GestureDetector`** solo detecta gestos completos (tap, swipe, etc.)
- **`Listener`** captura eventos de bajo nivel del sistema de punteros, garantizando que cualquier interacción sea detectada.

---

## 5. `HomeView` — Pantalla Principal Post-Login

**Archivo:** `lib/views/home_view.dart`

Muestra:
- Nombre del usuario logueado
- Contador regresivo de sesión en segundos
- Cambio de color (rojo cuando faltan ≤ 10 segundos)
- Botón de cierre de sesión con confirmación

Todo el contenido está envuelto en `InactivityDetector`, por lo que cualquier interacción con la pantalla reinicia el timer.

---

## 6. `main.dart` — Navegación Sensible a la Sesión

### Antes

```dart
home: const LoginView(),
```

### Después

```dart
home: Consumer<SessionViewModel>(
  builder: (context, sessionVM, _) {
    if (!sessionVM.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (sessionVM.isLoggedIn) {
      return const HomeView();
    }
    return const LoginView();
  },
),
```

Usamos `Consumer<SessionViewModel>` que:
1. Escucha cambios en `SessionViewModel` (via `ChangeNotifier`)
2. Muestra un indicador de carga mientras se inicializa el almacén encriptado
3. Decide qué pantalla mostrar según `isLoggedIn`
4. Cuando `logout()` cambia `isLoggedIn` a `false`, automáticamente reconstruye el árbol mostrando `LoginView` — sin necesidad de navegación explícita

---

## 7. Flujo Completo

```
App Inicia
   │
   ▼
SessionViewModel.init()
   ├─ Lee almacén encriptado
   ├─ ¿Token + username existen?
   │   ├─ Sí → ¿Timepo transcurrido < 60s?
   │   │         ├─ Sí → isLoggedIn = true → HomeView
   │   │         └─ No → clearSession → LoginView
   │   └─ No → LoginView
   │
LoginView
   ├─ Usuario ingresa credenciales
   └─ Login exitoso → SessionViewModel.startSession()
        ├─ Genera token (256 bits criptográficos)
        ├─ Guarda token + username + timestamp en almacén encriptado
        ├─ isLoggedIn = true
        ├─ Inicia timer de inactividad (60s)
        └─ Consumer reconstruye → HomeView
             │
             ├─ Usuario interactúa → resetInactivityTimer()
             │     └─ Reinicia contador + actualiza timestamp encriptado
             │
             ├─ Usuario NO interactúa por 60s
             │     └─ logout() automático
             │          ├─ Cancela timer
             │          ├─ Limpia almacén encriptado
             │          └─ isLoggedIn = false → LoginView
             │
             ├─ Usuario minimiza app
             │     └─ Se guarda timestamp actual
             │
             ├─ Usuario regresa después de >60s
             │     └─ logout() automático → LoginView
             │
             └─ Usuario presiona "Cerrar Sesión"
                   └─ logout() manual → LoginView
```

---

## Librerías Utilizadas

| Librería | Versión | Propósito |
|----------|---------|-----------|
| `flutter_secure_storage` | ^9.2.4 | Almacenamiento encriptado nativo (Android Keystore / iOS Keychain) |
| `provider` | ^6.1.5+1 | State management MVVM (ya existente) |
| `dart:async` | SDK | `Timer` para la cuenta regresiva de inactividad |
| `dart:math` | SDK | `Random.secure()` para generación criptográfica de tokens |
| `package:flutter/widgets.dart` | SDK | `WidgetsBindingObserver` para ciclo de vida, `Listener` para detección de interacción |

No se agregaron dependencias adicionales más allá de `flutter_secure_storage`. El resto utiliza exclusivamente la SDK de Dart/Flutter.

---

## Resumen de Seguridad

1. **Token de 256 bits generado con entropía criptográfica** (`Random.secure()`)
2. **Almacenamiento encriptado** vía `flutter_secure_storage` (AES-256 en Android, Keychain en iOS)
3. **Detección de inactividad por interacción** capturada a nivel de sistema de punteros (`Listener`)
4. **Protección contra manipulación del ciclo de vida**: si la app se minimiza, el tiempo de inactividad sigue corriendo
5. **Limpieza completa de datos sensibles** al hacer logout (token, username, timestamp eliminados del almacén seguro)
6. **Sin almacenamiento en memoria no controlada**: el token no se expone públicamente, solo se usa internamente para validar la sesión
