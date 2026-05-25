import 'dart:io'; // Para identificar la plataforma (Android/iOS)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para cerrar la app de forma limpia en Android
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../viewmodels/login_viewmodel.dart';
import '../data/services/security_service.dart'; // Importamos el nuevo servicio

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;

  // Instanciamos el servicio de seguridad
  final SecurityService _securityService = SecurityService();

  @override
  void initState() {
    super.initState();
    _initScreenProtection(); // Activamos la protección de pantalla existente
    _checkDeviceIntegrity(); // <- NUEVO: Ejecuta la validación de Fake GPS
  }

  @override
  void dispose() {
    _disableScreenProtection(); 
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Verifica si el usuario está usando herramientas de simulación de GPS
  void _checkDeviceIntegrity() {
    // Asegura que el contexto esté listo para mostrar diálogos de UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool isFakeGps = await _securityService.isFakeGpsDetected();
      
      if (isFakeGps && mounted) {
        _showFakeGpsAlert();
      }
    });
  }

  /// Despliega la alerta de bloqueo y fuerza el cierre de la aplicación
  void _showFakeGpsAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Bloquea el cierre al tocar fuera del diálogo
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Bloquea el botón "Back" nativo de Android
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.gpp_bad, color: Colors.redAccent, size: 30),
                SizedBox(width: 12),
                Text('Violación de Seguridad', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Se detectó el uso de una aplicación de ubicación simulada (Fake GPS).\n\n'
              'Por razones de seguridad y protección de datos, la aplicación se cerrará inmediatamente.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Cierre controlado de la aplicación según la plataforma
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // Cierre estándar y limpio para Android
                  } else if (Platform.isIOS) {
                    exit(0); // Cierre forzado para iOS (Apple no tiene equivalente nativo a pop)
                  }
                },
                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Configura las directivas de seguridad nativas del dispositivo
  Future<void> _initScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (e) {
      debugPrint("Error al inicializar la protección de pantalla: $e");
    }
  }

  /// Desactiva las restricciones de seguridad
  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageWithColorOff();
    } catch (e) {
      debugPrint("Error al desactivar la protección de pantalla: $e");
    }
  }

  void _handleLogin(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.login(
      _userController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${viewModel.user?.username}!'),
            backgroundColor: Colors.green,
          ),
        );
        _passwordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error de autenticación'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.flash_on, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text(
                  "ViteQ",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bienvenido",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.deepPurple, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Pantalla protegida contra fuga de datos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 40),

                // Campo: Usuario
                TextFormField(
                  controller: _userController,
                  keyboardType: TextInputType.text,
                  enabled: !viewModel.isLoading,
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? "Ingresa tu usuario" : null,
                ),
                const SizedBox(height: 20),

                // Campo: Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  enabled: !viewModel.isLoading,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? "Ingresa tu contraseña" : null,
                ),
                const SizedBox(height: 30),

                // Botón de Acción Principal / Indicador de Carga
                ElevatedButton(
                  onPressed: viewModel.isLoading ? null : () => _handleLogin(viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Iniciar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}