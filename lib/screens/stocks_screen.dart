import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'stock_edit_screen.dart';
import 'stock_form_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  List<dynamic> _stocks = [];
  List<dynamic> _filteredStocks = [];
  
  Map<int, String> _productNames = {};
  Map<int, String> _branchNames = {};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _loadData();
    _searchController.addListener(_filterStocks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _api.getStocks(),
        _api.getProductos(),
        _api.getSucursales(),
      ]);

      final rawStocks = results[0];
      final rawProducts = results[1];
      final rawBranches = results[2];

      final Map<int, String> prodNames = {};
      for (var p in rawProducts) {
        prodNames[p['id']] = p['nombre'];
      }

      final Map<int, String> brNames = {};
      for (var b in rawBranches) {
        brNames[b['id']] = b['nombre'];
      }

      if (mounted) {
        setState(() {
          _stocks = rawStocks;
          _filteredStocks = rawStocks;
          _productNames = prodNames;
          _branchNames = brNames;
          _isLoading = false;
        });
        _filterStocks();
      }
    } catch (e) {
      debugPrint('Error loading stock records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar existencias de la API'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _filterStocks() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStocks = _stocks;
      } else {
        _filteredStocks = _stocks.where((s) {
          final prodId = s['producto'] as int?;
          final branchId = s['sucursal'] as int?;
          
          final prodName = _productNames[prodId]?.toLowerCase() ?? '';
          final branchName = _branchNames[branchId]?.toLowerCase() ?? '';
          
          return prodName.contains(query) || branchName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteStock(int id, String productName, String branchName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Stock'),
        content: Text('¿Deseas eliminar el registro de stock para "$productName" en "$branchName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF51616F))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteStock(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro de stock para "$productName" eliminado'),
            backgroundColor: const Color(0xFF0F4C5C),
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar stock: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Existencias / Stocks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockFormScreen(api: _api),
          ),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por producto o sucursal...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8F9CA7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF8F9CA7)),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                fillColor: const Color(0xFFF6F9FC),
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F7A8C), width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List of stocks
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A8C)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF1F7A8C),
                    child: _filteredStocks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _stocks.isEmpty ? Icons.swap_horiz_outlined : Icons.search_off_rounded,
                                      size: 72,
                                      color: const Color(0xFF8F9CA7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _stocks.isEmpty
                                          ? 'No hay registros de stock'
                                          : 'No se encontraron resultados para tu búsqueda',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF51616F),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _stocks.isEmpty
                                          ? 'Pulsa el botón "+" abajo para registrar stock.'
                                          : 'Intenta con otras palabras clave.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStocks.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final stockRecord = _filteredStocks[index];
                              final id = stockRecord['id'] as int;
                              final prodId = stockRecord['producto'] as int;
                              final branchId = stockRecord['sucursal'] as int;
                              final quantity = (stockRecord['cantidad'] as num).toInt();

                              final pName = _productNames[prodId] ?? 'Producto #$prodId';
                              final bName = _branchNames[branchId] ?? 'Sucursal #$branchId';

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontSize: 16,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.store_outlined, size: 16, color: Color(0xFF8F9CA7)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  bName,
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: quantity == 0
                                                  ? Colors.redAccent.withOpacity(0.1)
                                                  : const Color(0xFF1F7A8C).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$quantity uds',
                                              style: TextStyle(
                                                color: quantity == 0 ? Colors.redAccent : const Color(0xFF1F7A8C),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1F7A8C)),
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StockEditScreen(
                                                      api: _api,
                                                      productoId: prodId,
                                                      productoNombre: pName,
                                                      stockId: id,
                                                      cantidadActual: quantity,
                                                    ),
                                                  ),
                                                ).then((_) => _loadData()),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                                onPressed: () => _deleteStock(id, pName, bName),
                                                tooltip: 'Eliminar',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}