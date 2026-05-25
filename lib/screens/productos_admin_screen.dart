import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'productos_form_screen.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  late final ApiService _api;
  bool _loading = true;
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _load();
  }

  Future<void> _load() async {
    final productos = await _api.getProductos();
    final categorias = await _api.getCategorias();
    setState(() {
      _productos = productos;
      _categorias = categorias;
      _loading = false;
    });
  }

  String _categoriaNombre(int id) {
    final c = _categorias.where((e) => e['id'] == id);
    if (c.isEmpty) return 'Sin categoria';
    return c.first['nombre'];
  }

  Future<void> _delete(int id) async {
    await _api.deleteProducto(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Productos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductoFormScreen(api: _api)),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (_, i) {
                final p = _productos[i];
                return ListTile(
                  title: Text('${p['nombre']} (${p['sku']})'),
                  subtitle: Text('Categoria: ${_categoriaNombre(p['categoria'])}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductoFormScreen(api: _api, producto: p),
                            ),
                          );
                          await _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(p['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}