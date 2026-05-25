import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriaFormScreen extends StatefulWidget {
  const CategoriaFormScreen({super.key, required this.api, this.categoria});
  final ApiService api;
  final Map<String, dynamic>? categoria;

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  late final TextEditingController _nombre;
  late final TextEditingController _prefijo;
  bool _activa = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.categoria?['nombre'] ?? '');
    _prefijo = TextEditingController(text: widget.categoria?['prefijo_sku'] ?? '');
    _activa = widget.categoria?['activa'] ?? true;
  }

  Future<void> _save() async {
    final data = {
      'nombre': _nombre.text.trim(),
      'prefijo_sku': _prefijo.text.trim().toUpperCase(),
      'activa': _activa,
    };

    if (widget.categoria == null) {
      await widget.api.createCategoria(data);
    } else {
      await widget.api.updateCategoria(widget.categoria!['id'], data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoria == null ? 'Nueva categoria' : 'Editar categoria')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _prefijo, decoration: const InputDecoration(labelText: 'Prefijo SKU')),
            SwitchListTile(
              value: _activa,
              onChanged: (v) => setState(() => _activa = v),
              title: const Text('Activa'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}