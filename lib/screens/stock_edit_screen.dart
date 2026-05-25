import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockEditScreen extends StatefulWidget {
  const StockEditScreen({
    super.key,
    required this.api,
    required this.productoId,
    required this.productoNombre,
    required this.stockId,
    required this.cantidadActual,
  });

  final ApiService api;
  final int productoId;
  final String productoNombre;
  final int? stockId;
  final int cantidadActual;

  @override
  State<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends State<StockEditScreen> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cantidadActual.toString());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cantidad = int.tryParse(_controller.text) ?? 0;
    await widget.api.upsertStock(
      productoId: widget.productoId,
      stockId: widget.stockId,
      cantidad: cantidad,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(cantidad);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Stock - ${widget.productoNombre}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}