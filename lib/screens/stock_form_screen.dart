import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockFormScreen extends StatefulWidget {
  const StockFormScreen({
    super.key,
    required this.api,
    required this.productos,
    required this.sucursales,
    this.stock,
  });

  final ApiService api;
  final List<dynamic> productos;
  final List<dynamic> sucursales;
  final Map<String, dynamic>? stock;

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  int? _productoId;
  int? _sucursalId;
  final TextEditingController _cantidad = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productoId = widget.stock?['producto'];
    _sucursalId = widget.stock?['sucursal'];
    _cantidad.text = (widget.stock?['cantidad'] ?? 0).toString();
  }

  Future<void> _save() async {
    final data = {
      'producto': _productoId,
      'sucursal': _sucursalId,
      'cantidad': int.tryParse(_cantidad.text) ?? 0,
    };

    if (widget.stock == null) {
      await widget.api.createStock(data);
    } else {
      await widget.api.updateStock(widget.stock!['id'], data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stock == null ? 'Nuevo stock' : 'Editar stock')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<int>(
              value: _productoId,
              items: widget.productos
                  .map((p) => DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['nombre']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _productoId = v),
              decoration: const InputDecoration(labelText: 'Producto'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _sucursalId,
              items: widget.sucursales
                  .map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['nombre']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sucursalId = v),
              decoration: const InputDecoration(labelText: 'Sucursal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cantidad,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}