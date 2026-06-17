import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/fake_gps_service.dart';
import '../data/services/usb_debug_service.dart';
import 'login_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _performSecurityChecks();
  }

  Future<void> _performSecurityChecks() async {
    final usbDebugEnabled = await UsbDebugService.isUsbDebugEnabled();

    if (!mounted) return;

    if (usbDebugEnabled) {
      await _showUsbDebugAlert();
      if (mounted) SystemNavigator.pop();
      return;
    }

    final isMock = await FakeGpsService.isMockLocationEnabled();

    if (!mounted) return;

    if (isMock) {
      await _showFakeGpsAlert();
      if (mounted) SystemNavigator.pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  Future<void> _showUsbDebugAlert() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.developer_mode, size: 30, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Brecha de Seguridad', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La Depuración USB está activa en este dispositivo.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'Esta configuración permite la comunicación directa con '
                'el sistema Android, exponiendo la aplicación a posibles '
                'ataques de instrumentación, extracción de datos y '
                'manipulación en tiempo real.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'Para proteger la información institucional:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                '1. Abre Ajustes → Opciones de Desarrollador\n'
                '2. Desactiva "Depuración USB"\n'
                '3. Vuelve a intentar acceder a la aplicación',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
              },
              child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFakeGpsAlert() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.gps_off, size: 48, color: Colors.red),
        title: const Text('Fake GPS Detectado'),
        content: const Text(
          'Se ha detectado una aplicación de GPS falso en el dispositivo. '
          'Por seguridad, la aplicación se cerrará.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Verificando seguridad...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
