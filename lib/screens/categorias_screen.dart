import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'categoria_form_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  List<dynamic> _categorias = [];
  List<dynamic> _filteredCategorias = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _loadCategorias();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final cats = await _api.getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _filteredCategorias = cats;
          _isLoading = false;
        });
        _filterCategories();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar categorías de la API'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCategorias = _categorias;
      } else {
        _filteredCategorias = _categorias.where((c) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final prefijo = (c['prefijo_sku'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || prefijo.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "$name"?'),
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
        await _api.deleteCategoria(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "$name" eliminada'),
            backgroundColor: const Color(0xFF0F4C5C),
          ),
        );
        _loadCategorias();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar categoría: $e'),
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
        title: const Text('Categorías'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoriaFormScreen(api: _api),
          ),
        ).then((_) => _loadCategorias()),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o prefijo...',
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

          // Categories list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A8C)))
                : RefreshIndicator(
                    onRefresh: _loadCategorias,
                    color: const Color(0xFF1F7A8C),
                    child: _filteredCategorias.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _categorias.isEmpty ? Icons.category_outlined : Icons.search_off_rounded,
                                      size: 72,
                                      color: const Color(0xFF8F9CA7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _categorias.isEmpty
                                          ? 'No hay categorías registradas'
                                          : 'No se encontraron resultados para tu búsqueda',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF51616F),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _categorias.isEmpty
                                          ? 'Pulsa el botón "+" abajo para registrar una nueva categoría.'
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
                            itemCount: _filteredCategorias.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final cat = _filteredCategorias[index];
                              final id = cat['id'] as int;
                              final nombre = cat['nombre'] ?? '';
                              final prefijo = cat['prefijo_sku'] ?? '';
                              final activa = cat['activa'] ?? true;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Status dot
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: activa ? const Color(0xFF2E8B57) : const Color(0xFF8F9CA7),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Text info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombre,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontSize: 16,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Prefijo SKU: $prefijo',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1F7A8C),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1F7A8C)),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CategoriaFormScreen(api: _api, categoria: cat),
                                              ),
                                            ).then((_) => _loadCategorias()),
                                            tooltip: 'Editar',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                            onPressed: () => _deleteCategory(id, nombre),
                                            tooltip: 'Eliminar',
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