import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/config.dart';
import 'auth_gate.dart';
import 'stock_edit_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  List<dynamic> _productos = [];
  List<dynamic> _filteredProductos = [];
  Map<int, String> _categoriaMap = {};
  Map<int, Map<String, dynamic>> _stockMap = {}; // productoId -> stockObj (for defaultSucursalId)
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _loadData();
    _searchController.addListener(_filterProducts);
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
        _api.getProductos(),
        _api.getCategorias(),
        _api.getStocks(),
      ]);

      final rawProductos = results[0];
      final rawCategorias = results[1];
      final rawStocks = results[2];

      // Build categories map
      final Map<int, String> catMap = {};
      for (var cat in rawCategorias) {
        catMap[cat['id']] = cat['nombre'];
      }

      // Build stocks map filtered by defaultSucursalId
      final Map<int, Map<String, dynamic>> stkMap = {};
      for (var stk in rawStocks) {
        final prodId = stk['producto'] as int;
        final sucId = stk['sucursal'] as int;
        if (sucId == defaultSucursalId) {
          stkMap[prodId] = Map<String, dynamic>.from(stk);
        }
      }

      if (mounted) {
        setState(() {
          _productos = rawProductos;
          _filteredProductos = rawProductos;
          _categoriaMap = catMap;
          _stockMap = stkMap;
          _isLoading = false;
        });
        _filterProducts();
      }
    } catch (e) {
      debugPrint('Error loading product catalog: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar datos del catálogo'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredProductos = _productos;
      } else {
        _filteredProductos = _productos.where((p) {
          final nombre = (p['nombre'] ?? '').toString().toLowerCase();
          final sku = (p['sku'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || sku.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF51616F))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AuthGate(authService: widget.authService),
        ),
      );
    }
  }

  void _editStock(int prodId, String prodName) {
    final stockObj = _stockMap[prodId];
    final stockId = stockObj?['id'] as int?;
    final cantidad = (stockObj?['cantidad'] as num?)?.toInt() ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockEditScreen(
          api: _api,
          productoId: prodId,
          productoNombre: prodName,
          stockId: stockId,
          cantidadActual: cantidad,
        ),
      ),
    ).then((updatedQty) {
      if (updatedQty != null) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar lista',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
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
                hintText: 'Buscar por nombre o SKU...',
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

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A8C)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF1F7A8C),
                    child: _filteredProductos.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _productos.isEmpty ? Icons.inventory_2_outlined : Icons.search_off_rounded,
                                      size: 72,
                                      color: const Color(0xFF8F9CA7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _productos.isEmpty
                                          ? 'No hay productos registrados'
                                          : 'No se encontraron resultados para tu búsqueda',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF51616F),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _productos.isEmpty
                                          ? 'Por favor, contacta a un administrador.'
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
                            itemCount: _filteredProductos.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final prod = _filteredProductos[index];
                              final id = prod['id'] as int;
                              final name = prod['nombre'] ?? '';
                              final sku = prod['sku'] ?? 'SIN SKU';
                              final price = double.tryParse(prod['precio']?.toString() ?? '0.0') ?? 0.0;
                              final catId = prod['categoria'] as int?;
                              final catName = _categoriaMap[catId] ?? 'Desconocida';
                              final stockObj = _stockMap[id];
                              final stock = (stockObj?['cantidad'] as num?)?.toInt() ?? 0;

                              return Card(
                                child: InkWell(
                                  onTap: () => _editStock(id, name),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontSize: 16,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF6F9FC),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFD7E2EA)),
                                                    ),
                                                    child: Text(
                                                      sku,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFF1F7A8C),
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    catName,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '\$${price.toStringAsFixed(2)}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF0F4C5C),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Stock Sucursal 1',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontSize: 10,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: stock == 0
                                                    ? Colors.redAccent.withOpacity(0.1)
                                                    : const Color(0xFF2E8B57).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$stock uds',
                                                style: TextStyle(
                                                  color: stock == 0 ? Colors.redAccent : const Color(0xFF2E8B57),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: const [
                                                Text(
                                                  'Ajustar stock',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF1F7A8C),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 14,
                                                  color: Color(0xFF1F7A8C),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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