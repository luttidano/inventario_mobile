import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'categoria_form_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final ApiService _api;
  bool _loading = true;
  List<dynamic> _categorias = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getCategorias();
    setState(() {
      _categorias = data;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await _api.deleteCategoria(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CategoriaFormScreen(api: _api)),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categorias.length,
              itemBuilder: (_, i) {
                final c = _categorias[i];
                return ListTile(
                  title: Text(c['nombre']),
                  subtitle: Text(c['prefijo_sku']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoriaFormScreen(api: _api, categoria: c),
                            ),
                          );
                          await _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(c['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}