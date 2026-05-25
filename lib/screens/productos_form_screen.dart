import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, required this.api, this.producto});
  final ApiService api;
  final Map<String, dynamic>? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final TextEditingController _sku;
  List<dynamic> _categorias = [];
  int? _categoriaId;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.producto?['nombre'] ?? '');
    _descripcion = TextEditingController(text: widget.producto?['descripcion'] ?? '');
    _precio = TextEditingController(text: widget.producto?['precio'] ?? '');
    _sku = TextEditingController(text: widget.producto?['sku'] ?? '');
    _categoriaId = widget.producto?['categoria'];
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    final cats = await widget.api.getCategorias();
    setState(() => _categorias = cats);
  }

  Future<void> _save() async {
    if (_categoriaId == null) return;

    final data = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'precio': _precio.text.trim(),
      'categoria': _categoriaId,
      'sku': _sku.text.trim(),
    };

    if (widget.producto == null) {
      await widget.api.createProducto(data);
    } else {
      await widget.api.updateProducto(widget.producto!['id'], data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto == null ? 'Nuevo producto' : 'Editar producto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _descripcion, decoration: const InputDecoration(labelText: 'Descripcion')),
            TextField(controller: _precio, decoration: const InputDecoration(labelText: 'Precio')),
            TextField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _categoriaId,
              items: _categorias
                  .map((c) => DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['nombre']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}