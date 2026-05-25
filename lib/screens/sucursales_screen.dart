import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'sucursal_form_screen.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  late final ApiService _api;
  bool _loading = true;
  List<dynamic> _sucursales = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getSucursales();
    setState(() {
      _sucursales = data;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await _api.deleteSucursal(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sucursales')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SucursalFormScreen(api: _api)),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _sucursales.length,
              itemBuilder: (_, i) {
                final s = _sucursales[i];
                return ListTile(
                  title: Text(s['nombre']),
                  subtitle: Text('${s['codigo']} · ${s['direccion']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SucursalFormScreen(api: _api, sucursal: s),
                            ),
                          );
                          await _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(s['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}