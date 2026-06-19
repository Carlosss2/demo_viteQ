import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecureAppDemo());
}

class SecureAppDemo extends StatefulWidget {
  const SecureAppDemo({super.key});

  @override
  State<SecureAppDemo> createState() => _SecureAppDemoState();
}

class _SecureAppDemoState extends State<SecureAppDemo> {
  bool _checking = true;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _checkUsbDebug();
  }

  void _checkUsbDebug() {
    if (kDebugMode) {
      _checking = false;
      return;
    }
    _checkUsbDebugAsync();
  }

  Future<void> _checkUsbDebugAsync() async {
    try {
      const channel = MethodChannel('com.example.secure_app_demo/usb_debug');
      final enabled = await channel.invokeMethod<bool>('isUsbDebugEnabled') ?? false;

      if (enabled) {
        if (!mounted) return;
        setState(() {
          _checking = false;
          _blocked = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBlockingDialog();
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _checking = false);
    }
  }

  void _showBlockingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Bloqueo de Seguridad'),
          content: const Text(
            'Se ha detectado que la Depuración USB está activada en este '
            'dispositivo.\n\n'
            'Por políticas de seguridad, la aplicación no puede continuar '
            'su ejecución.\n\n'
            'Por favor, desactive la Depuración USB en:\n'
            'Ajustes → Opciones de Desarrollador → Depuración USB\n\n'
            'Una vez desactivada, reinicie la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Cerrar Aplicación'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_blocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: SizedBox.shrink(),
        ),
      );
    }

    return MaterialApp(
      title: 'Secure App Demo - Ofuscacion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const LoginScreen(),
    );
  }
}
