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
  bool _isLoading = true;
  List<dynamic> _productos = [];
  List<dynamic> _filteredProductos = [];
  Map<int, String> _categoriaMap = {};
  Map<int, int> _stockMap = {}; // productoId -> totalStock
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

      // Build stocks count map
      final Map<int, int> stkMap = {};
      for (var stk in rawStocks) {
        final prodId = stk['producto'] as int;
        final qty = (stk['cantidad'] as num).toInt();
        stkMap[prodId] = (stkMap[prodId] ?? 0) + qty;
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
      debugPrint('Error loading product data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar productos de la API'),
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

  Future<void> _deleteProduct(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que deseas eliminar "$name"? Esta acción no se puede deshacer.'),
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
        await _api.deleteProducto(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "$name" eliminado'),
            backgroundColor: const Color(0xFF0F4C5C),
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
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
        title: const Text('Catálogo de Productos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductoFormScreen(api: _api),
          ),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search & Info Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
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
              ],
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
                                          ? 'Pulsa el botón "+" abajo para registrar un nuevo producto.'
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
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final prod = _filteredProductos[index];
                              final id = prod['id'] as int;
                              final name = prod['nombre'] ?? '';
                              final sku = prod['sku'] ?? 'SIN SKU';
                              final price = double.tryParse(prod['precio']?.toString() ?? '0.0') ?? 0.0;
                              final catId = prod['categoria'] as int?;
                              final catName = _categoriaMap[catId] ?? 'Desconocida';
                              final stock = _stockMap[id] ?? 0;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF6F9FC),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFD7E2EA)),
                                                      ),
                                                      child: Text(
                                                        sku,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '\$${price.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: const Color(0xFF0F4C5C),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.assessment_outlined,
                                                size: 16,
                                                color: stock == 0 ? Colors.redAccent : const Color(0xFF2E8B57),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Stock Total: ',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              Text(
                                                '$stock unidades',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: stock == 0 ? Colors.redAccent : const Color(0xFF12263A),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1F7A8C)),
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ProductoFormScreen(api: _api, producto: prod),
                                                  ),
                                                ).then((_) => _loadData()),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                                onPressed: () => _deleteProduct(id, name),
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
