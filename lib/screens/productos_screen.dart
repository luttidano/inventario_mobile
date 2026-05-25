import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'stock_edit_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  late final ApiService _api;
  bool _loading = true;
  List<dynamic> _productos = [];
  List<dynamic> _stocks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _load();
  }

  Future<void> _load() async {
    try {
      final productos = await _api.getProductos();
      final stocks = await _api.getStocks();
      setState(() {
        _productos = productos;
        _stocks = stocks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _findStockId(int productoId) {
    final stock = _stocks.where(
      (s) => s['producto'] == productoId && s['sucursal'] == 1,
    );
    if (stock.isEmpty) return null;
    return stock.first['id'] as int?;
  }

  int _findStockCantidad(int productoId) {
    final stock = _stocks.where(
      (s) => s['producto'] == productoId && s['sucursal'] == 1,
    );
    if (stock.isEmpty) return 0;
    return stock.first['cantidad'] as int? ?? 0;
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _productos.length,
                  itemBuilder: (_, i) {
                    final p = _productos[i];
                    final stockId = _findStockId(p['id']);
                    final stockCantidad = _findStockCantidad(p['id']);
                    return ListTile(
                      title: Text('${p['nombre']} (${p['sku']})'),
                      subtitle: Text('Stock: $stockCantidad'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final updated = await Navigator.of(context).push<int?>(
                            MaterialPageRoute(
                              builder: (_) => StockEditScreen(
                                api: _api,
                                productoId: p['id'],
                                productoNombre: p['nombre'],
                                stockId: stockId,
                                cantidadActual: stockCantidad,
                              ),
                            ),
                          );
                          if (updated != null) {
                            await _load();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}