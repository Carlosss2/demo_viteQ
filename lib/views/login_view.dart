import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart'; // 1. Importamos el paquete de seguridad
import '../viewmodels/login_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    _initScreenProtection(); // 2. Activamos la protección al construir la vista
  }

  @override
  void dispose() {
    _disableScreenProtection(); // 3. Liberamos la protección al destruir la vista
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Configura las directivas de seguridad nativas del dispositivo
  Future<void> _initScreenProtection() async {
    try {
      // Bloquea capturas y grabaciones de pantalla activas (En Android muestra pantalla negra)
      await ScreenProtector.preventScreenshotOn();
      
      // Protege los datos en la vista de aplicaciones recientes (Multitarea)
      // En iOS aplica un filtro/opacidad automáticamente al salir de la app
      await ScreenProtector.protectDataLeakageWithColor(Colors.black);
    } catch (e) {
      debugPrint("Error al inicializar la protección de pantalla: $e");
    }
  }

  /// Desactiva las restricciones de seguridad para no perjudicar la experiencia en el resto de la app
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
        // NOTA DE SEGURIDAD: Limpiar credenciales de la memoria RAM inmediatamente
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
      backgroundColor: const Color(0xfff5f7fa),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.shield_outlined, size: 80, color: Colors.blueAccent), // Icono cambiado por semántica de seguridad
                const SizedBox(height: 16),
                const Text(
                  "Acceso Seguro",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
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
                    backgroundColor: Colors.blueAccent,
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