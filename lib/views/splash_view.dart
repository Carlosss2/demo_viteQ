import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/fake_gps_service.dart';
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
    _checkFakeGps();
  }

  Future<void> _checkFakeGps() async {
    final isMock = await FakeGpsService.isMockLocationEnabled();

    if (!mounted) return;

    if (isMock) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.gps_off, size: 48, color: Colors.red),
          title: const Text('Fake GPS Detectado'),
          content: const Text(
            'Se ha detectado una aplicación de GPS falso en el dispositivo. '
            'Por seguridad, la aplicación se cerrará.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      if (mounted) {
        SystemNavigator.pop();
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
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
