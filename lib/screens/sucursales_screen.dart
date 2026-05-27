import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'sucursal_form_screen.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  List<dynamic> _sucursales = [];
  List<dynamic> _filteredSucursales = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _loadSucursales();
    _searchController.addListener(_filterBranches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSucursales() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final branches = await _api.getSucursales();
      if (mounted) {
        setState(() {
          _sucursales = branches;
          _filteredSucursales = branches;
          _isLoading = false;
        });
        _filterBranches();
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar sucursales de la API'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _filterBranches() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredSucursales = _sucursales;
      } else {
        _filteredSucursales = _sucursales.where((s) {
          final nombre = (s['nombre'] ?? '').toString().toLowerCase();
          final codigo = (s['codigo'] ?? '').toString().toLowerCase();
          final direccion = (s['direccion'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || codigo.contains(query) || direccion.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteBranch(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sucursal'),
        content: Text('¿Estás seguro de que deseas eliminar la sucursal "$name"?'),
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
        await _api.deleteSucursal(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sucursal "$name" eliminada'),
            backgroundColor: const Color(0xFF0F4C5C),
          ),
        );
        _loadSucursales();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar sucursal: $e'),
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
        title: const Text('Sucursales'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SucursalFormScreen(api: _api),
          ),
        ).then((_) => _loadSucursales()),
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
                hintText: 'Buscar por nombre, código o dirección...',
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

          // List of branches
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A8C)))
                : RefreshIndicator(
                    onRefresh: _loadSucursales,
                    color: const Color(0xFF1F7A8C),
                    child: _filteredSucursales.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _sucursales.isEmpty ? Icons.store_outlined : Icons.search_off_rounded,
                                      size: 72,
                                      color: const Color(0xFF8F9CA7),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _sucursales.isEmpty
                                          ? 'No hay sucursales registradas'
                                          : 'No se encontraron resultados para tu búsqueda',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF51616F),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _sucursales.isEmpty
                                          ? 'Pulsa el botón "+" abajo para registrar una nueva sucursal.'
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
                            itemCount: _filteredSucursales.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final branch = _filteredSucursales[index];
                              final id = branch['id'] as int;
                              final nombre = branch['nombre'] ?? '';
                              final codigo = branch['codigo'] ?? '';
                              final direccion = branch['direccion'] ?? 'Sin dirección registrada';
                              final activa = branch['activa'] ?? true;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
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
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              nombre,
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF6F9FC),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFD7E2EA)),
                                            ),
                                            child: Text(
                                              codigo,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF0F4C5C),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF8F9CA7)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              direccion,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1F7A8C)),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SucursalFormScreen(api: _api, sucursal: branch),
                                              ),
                                            ).then((_) => _loadSucursales()),
                                            tooltip: 'Editar',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                            onPressed: () => _deleteBranch(id, nombre),
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