import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'stock_form_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  late final ApiService _api;
  bool _loading = true;
  List<dynamic> _stocks = [];
  List<dynamic> _productos = [];
  List<dynamic> _sucursales = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _load();
  }

  Future<void> _load() async {
    final stocks = await _api.getStocks();
    final productos = await _api.getProductos();
    final sucursales = await _api.getSucursales();
    setState(() {
      _stocks = stocks;
      _productos = productos;
      _sucursales = sucursales;
      _loading = false;
    });
  }

  String _productoNombre(int id) {
    final p = _productos.where((e) => e['id'] == id);
    if (p.isEmpty) return 'Producto';
    return p.first['nombre'];
  }

  String _sucursalNombre(int id) {
    final s = _sucursales.where((e) => e['id'] == id);
    if (s.isEmpty) return 'Sucursal';
    return s.first['nombre'];
  }

  Future<void> _delete(int id) async {
    await _api.deleteStock(id);
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
        title: const Text('Stocks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StockFormScreen(api: _api, productos: _productos, sucursales: _sucursales)),
          );
          await _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _stocks.length,
              itemBuilder: (_, i) {
                final s = _stocks[i];
                return ListTile(
                  title: Text(_productoNombre(s['producto'])),
                  subtitle: Text('${_sucursalNombre(s['sucursal'])} · Cantidad: ${s['cantidad']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockFormScreen(
                                api: _api,
                                productos: _productos,
                                sucursales: _sucursales,
                                stock: s,
                              ),
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