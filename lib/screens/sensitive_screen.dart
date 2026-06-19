import 'package:flutter/material.dart';
import '../services/sensitive_data_processor.dart';

class SensitiveScreen extends StatefulWidget {
  const SensitiveScreen({super.key});

  @override
  State<SensitiveScreen> createState() => _SensitiveScreenState();
}

class _SensitiveScreenState extends State<SensitiveScreen> {
  final _processor = SensitiveDataProcessor();
  Map<String, dynamic>? _result;

  void _executeProcessing() {
    final result = _processor.processPayment(2500.00, "premium");
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Procesamiento Sensible")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Datos del cliente:",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _infoRow("Nombre", _processor.customerName),
            _infoRow("Tarjeta", _processor.creditCardNumber),
            _infoRow("API URL", _processor.internalApiUrl),
            _infoRow("Descuento", "${_processor.discountPercentage}%"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _executeProcessing,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Ejecutar Procesamiento"),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Text("Resultado:",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildResultCard(_result!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: result.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text("${e.key}:",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Text("${e.value}")),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
