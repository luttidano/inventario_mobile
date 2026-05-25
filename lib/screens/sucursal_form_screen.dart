import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SucursalFormScreen extends StatefulWidget {
  const SucursalFormScreen({super.key, required this.api, this.sucursal});
  final ApiService api;
  final Map<String, dynamic>? sucursal;

  @override
  State<SucursalFormScreen> createState() => _SucursalFormScreenState();
}

class _SucursalFormScreenState extends State<SucursalFormScreen> {
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  late final TextEditingController _direccion;
  bool _activa = true;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.sucursal?['nombre'] ?? '');
    _codigo = TextEditingController(text: widget.sucursal?['codigo'] ?? '');
    _direccion = TextEditingController(text: widget.sucursal?['direccion'] ?? '');
    _activa = widget.sucursal?['activa'] ?? true;
  }

  Future<void> _save() async {
    final data = {
      'nombre': _nombre.text.trim(),
      'codigo': _codigo.text.trim().toUpperCase(),
      'direccion': _direccion.text.trim(),
      'activa': _activa,
    };

    if (widget.sucursal == null) {
      await widget.api.createSucursal(data);
    } else {
      await widget.api.updateSucursal(widget.sucursal!['id'], data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.sucursal == null ? 'Nueva sucursal' : 'Editar sucursal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _codigo, decoration: const InputDecoration(labelText: 'Codigo')),
            TextField(controller: _direccion, decoration: const InputDecoration(labelText: 'Direccion')),
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