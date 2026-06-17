import 'package:flutter/material.dart';
import '../data/services/secure_storage_service.dart';

class SecureStorageHome extends StatefulWidget {
  const SecureStorageHome({super.key});

  @override
  State<SecureStorageHome> createState() => _SecureStorageHomeState();
}

class _SecureStorageHomeState extends State<SecureStorageHome> {
  final SecureStorageService _storageService = SecureStorageService();
  Map<String, String?> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final data = await _storageService.readAll();
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _generateDummy() async {
    await _storageService.populateDummyData();
    await _refresh();
  }

  Widget _fieldTile(String label, String? value) {
    final display = (value != null && value.isNotEmpty) ? value : 'Vacío';
    final isEmpty = value == null || value.isEmpty;
    return Card(
      child: ListTile(
        leading: Icon(
          isEmpty ? Icons.error_outline : Icons.check_circle,
          color: isEmpty ? Colors.red : Colors.green,
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(display),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrado Remoto (FCM)'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _fieldTile('Matrícula', _data['matricula']),
                        _fieldTile('Contraseña', _data['password']),
                        _fieldTile('Nombre', _data['nombre']),
                        _fieldTile('Correo Institucional', _data['correo_institucional']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _generateDummy,
                          icon: const Icon(Icons.dataset),
                          label: const Text('Generar Datos de Prueba'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refrescar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
