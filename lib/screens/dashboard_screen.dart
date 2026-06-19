import 'package:flutter/material.dart';
import 'sensitive_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String user;
  final String token;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenido, $user",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security, color: Colors.red),
                title: const Text("Procesamiento de Datos Sensibles"),
                subtitle: const Text("Acceder al modulo de pagos y encriptacion"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SensitiveScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
