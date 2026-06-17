# Reporte Técnico — RASP: Detección de Depuración USB, Frida y Root

## 1. Arquitectura de la Solución

La validación de seguridad sigue una arquitectura de **2 capas de verificación** con comunicación Dart ↔ Kotlin mediante **MethodChannel**:

```
┌─────────────────────────────────────────────────────────┐
│                    DART (Flutter)                        │
│                                                         │
│  SplashView                     LoginView                │
│  ┌─────────────────┐           ┌──────────────────┐     │
│  │ initState() ─────┼──────────►│ initState() ─────┼─┐   │
│  │ _performSecurity│           │ _checkDevice     │ │   │
│  │ Checks()        │           │ Integrity()      │ │   │
│  └────────┬────────┘           └────────┬─────────┘ │   │
│           │                              │           │   │
│     ┌─────▼──────┐                ┌──────▼──────┐   │   │
│     │ UsbDebug   │                │ UsbDebug    │   │   │
│     │ Service    │                │ Service     │   │   │
│     │ Integrity  │                │ Integrity   │   │   │
│     │ Service    │                │ Service     │   │   │
│     └─────┬──────┘                └──────┬──────┘   │   │
│           │ MethodChannel               │ MethodCh. │   │
└───────────┼─────────────────────────────┼───────────┘   │
            │                             │               │
┌───────────▼─────────────────────────────▼───────────┐   │
│              KOTLIN (Android Nativo)                  │   │
│                                                       │   │
│  MainActivity.kt                                      │   │
│  ┌─────────────────────────────────────────────────┐  │   │
│  │ isUsbDebugEnabled()                             │  │   │
│  │   → Settings.Global.ADB_ENABLED                │  │   │
│  │                                                 │  │   │
│  │ isFridaDetected()                              │  │   │
│  │   ├─ isFridaOnMaps() → /proc/self/maps         │  │   │
│  │   ├─ isFridaPortOpen() → 127.0.0.1:27042/3     │  │   │
│  │   ├─ isFridaPipePresent() → /data/local/tmp/   │  │   │
│  │   └─ isFridaProcessRunning() → ps -A           │  │   │
│  │                                                 │  │   │
│  │ isRootDetected()                                │  │   │
│  │   ├─ isSuBinaryPresent() → 10 rutas de su       │  │   │
│  │   ├─ isRootedByBuildTags() → test-keys          │  │   │
│  │   └─ hasRootPermissions() → su -c id            │  │   │
│  └─────────────────────────────────────────────────┘  │   │
└───────────────────────────────────────────────────────┘   │
                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Justificación del Método Elegido (Opción B — Código Nativo)

Se eligió **MethodChannel + código nativo Kotlin** en lugar de paquetes de la comunidad porque:

1. **Anti-bypass**: Las validaciones en Kotlin se ejecutan en la capa JVM, lo que obliga al atacante a hookear métodos Java/Kotlin (Frida puede hacerlo, pero es más complejo que modificar Dart).
2. **Control total**: Podemos leer `/proc/self/maps`, verificar puertos TCP y escanear el sistema de archivos sin depender de APIs públicas de Android que puedan ser falseadas.
3. **Portabilidad**: No depende de plugins de terceros que puedan quedar obsoletos.

---

## 3. Implementación por Archivo

### `android/.../MainActivity.kt` (Lógica nativa)

| Método | Línea | Descripción |
|---|---|---|
| `isUsbDebugEnabled()` | 89-103 | Lee `Settings.Global.ADB_ENABLED`. Retorna `true` si ADB está activo |
| `isFridaDetected()` | 105-107 | OR de 4 métodos de detección de Frida |
| `isFridaOnMaps()` | 109-118 | Escanea `/proc/self/maps` buscando "frida" (las librerías de Frida se mapean en memoria) |
| `isFridaPortOpen()` | 120-134 | Intenta conectar a `127.0.0.1:27042` y `27043` (puertos por defecto de frida-server) |
| `isFridaPipePresent()` | 136-143 | Busca `/data/local/tmp/frida-server` (binario de Frida en almacenamiento temporal) |
| `isFridaProcessRunning()` | 145-156 | Ejecuta `ps -A` y busca procesos "frida" |
| `isRootDetected()` | 158-160 | OR de 3 métodos de detección de root |
| `isSuBinaryPresent()` | 162-176 | Busca el binario `su` en 10 rutas conocidas del sistema Android |
| `isRootedByBuildTags()` | 178-181 | Verifica que `Build.TAGS` contenga "test-keys" (dispositivos rooteados suelen tener build test-keys) |
| `hasRootPermissions()` | 183-193 | Ejecuta `su -c id` y verifica que el UID resultante sea 0 (root) |
| `configureFlutterEngine()` | 18-54 | Registra los 3 MethodChannels (`fake_gps`, `usb_debug`, `integrity`) |

### `lib/data/services/usb_debug_service.dart` (Puente Dart nativo)

| Método | Línea | Descripción |
|---|---|---|
| `isUsbDebugEnabled()` | 7-23 | Si `kDebugMode=true` retorna `false`. Si no, invoca el MethodChannel `usb_debug` |
| `kDebugMode` check | 8-10 | **Excepción de desarrollo**: en debug mode retorna `false` para permitir programar sin bloqueo |

### `lib/data/services/integrity_service.dart` (Puente Dart Frida/Root)

| Método | Línea | Descripción |
|---|---|---|
| `isFridaDetected()` | 7-16 | Invoca MethodChannel `integrity` → `isFridaDetected` |
| `isRootDetected()` | 18-27 | Invoca MethodChannel `integrity` → `isRootDetected` |
| `isIntegrityCompromised()` | 29-38 | OR de los dos anteriores del lado Kotlin |

### `lib/views/splash_view.dart` (Primer punto de verificación)

| Bloque | Línea | Descripción |
|---|---|---|
| `initState()` | 18-21 | Llama a `_performSecurityChecks()` al montar el splash |
| Chequeo USB Debug | 24-32 | Si USB Debug activo → muestra alerta y cierra app |
| Chequeo Frida | 34-44 | Si Frida detectado → alerta y cierra app |
| Chequeo Root | 46-57 | Si Root detectado → alerta y cierra app |
| Chequeo Fake GPS | 59-66 | Si Fake GPS activo → alerta y cierra app |
| `_showTamperingAlert()` | 140-176 | AlertDialog persistente (`barrierDismissible: false`, `PopScope canPop: false`) con botón que llama `SystemNavigator.pop()` |

### `lib/views/login_view.dart` (Segundo punto de verificación — redundante)

| Bloque | Línea | Descripción |
|---|---|---|
| `initState()` | 30-34 | Llama `_checkDeviceIntegrity()` al mostrar el login |
| Re-chequeo USB Debug | 46-54 | Vuelve a verificar USB Debug (por si se bypaseó el splash) |
| Re-chequeo Frida | 56-64 | Idem para Frida |
| Re-chequeo Root | 66-74 | Idem para Root |
| Re-chequeo Fake GPS | 76-79 | Idem para Fake GPS |

---

## 4. Flujo de Ejecución en Release Mode

```
App abre
  ↓
SplashView.initState()
  ↓
¿USB Debug activo?  ──SÍ──► Alerta → SystemNavigator.pop()
  ↓ NO
¿Frida detectado?  ──SÍ──► Alerta → SystemNavigator.pop()
  ↓ NO
¿Root detectado?  ──SÍ──► Alerta → SystemNavigator.pop()
  ↓ NO
¿Fake GPS activo?  ──SÍ──► Alerta → SystemNavigator.pop()
  ↓ NO
LoginView.initState()
  ↓
Re-verifica USB Debug, Frida, Root, Fake GPS
  ↓ (todo limpio)
Usuario puede iniciar sesión
```

---

## 5. Gestión del Entorno de Desarrollo

Todos los servicios (`usb_debug_service.dart:8`, `integrity_service.dart:8-9`) verifican `kDebugMode`:

```dart
if (kDebugMode) return false;
```

Cuando se ejecuta con `flutter run` (debug mode), las validaciones se desactivan automáticamente. En `flutter run --release` o APK release, `kDebugMode = false` y las protecciones se activan.

---

## 6. Análisis Crítico: ¿Es 100% infalible contra Frida?

**No.** Un atacante con Frida puede hookear los métodos Java/Kotlin de `MainActivity` usando `Java.use()` y modificar el valor de retorno de `isUsbDebugEnabled()`, `isFridaDetected()` y `isRootDetected()` para que siempre retornen `false`. Esto se demostró con el script `bypass.js`.

**Capas adicionales que añadiría:**

1. **Ofuscación con ProGuard/R8**: Renombrar métodos y clases de Kotlin para que los nombres como `isUsbDebugEnabled` no sean legibles en el bytecode.
2. **Chequeos desde native C/C++ (NDK)**: Implementar las detecciones en C++ compilado como `.so`, donde hookear con Frida requiere ingeniería inversa más avanzada (ARM64 assembly).
3. **Validación server-side**: El backend debe enviar un nonce cifrado que la app debe firmar con una clave derivada del estado de integridad; si el servidor detecta manipulación, revoca la sesión.
4. **Detección de Frida en Dart**: Verificar en tiempo de ejecución si las funciones nativas han sido reemplazadas (comparar firmas de métodos).
5. **Scans periódicos**: Ejecutar las validaciones cada N segundos mediante un Timer, no solo al iniciar.
6. **SSLPinning + Certificate Transparency**: Evitar que Frida pueda interceptar tráfico de red con su propio certificado CA.

---

## 7. Repositorio

URL del repositorio: *(a insertar por el alumno)*

---

## 8. Capturas de Pantalla

*(a insertar por el alumno)*
