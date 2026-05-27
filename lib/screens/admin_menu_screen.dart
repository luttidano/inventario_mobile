import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'auth_gate.dart';
import 'productos_admin_screen.dart';
import 'categorias_screen.dart';
import 'sucursales_screen.dart';
import 'stocks_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late final ApiService _api;
  bool _isLoading = true;

  int _productsCount = 0;
  int _categoriesCount = 0;
  int _branchesCount = 0;
  int _totalStock = 0;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.authService);
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await Future.wait([
        _api.getProductos(),
        _api.getCategorias(),
        _api.getSucursales(),
        _api.getStocks(),
      ]);

      final products = data[0];
      final categories = data[1];
      final branches = data[2];
      final stocks = data[3];

      int calculatedStock = 0;
      for (var s in stocks) {
        calculatedStock += (s['cantidad'] as num).toInt();
      }

      if (mounted) {
        setState(() {
          _productsCount = products.length;
          _categoriesCount = categories.length;
          _branchesCount = branches.length;
          _totalStock = calculatedStock;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard metrics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar métricas',
            onPressed: _fetchMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMetrics,
        color: const Color(0xFF1F7A8C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header Section
              Text(
                'Hola, Administrador',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0F4C5C),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí tienes un resumen del estado actual de tu inventario.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Metrics Grid
              Text(
                'Métricas del Sistema',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildMetricsGrid(),

              const SizedBox(height: 32),

              // Actions Section
              Text(
                'Administración de Recursos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: Color(0xFF1F7A8C)),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard('Productos', _productsCount.toString(), Icons.inventory_2_outlined, const Color(0xFF1F7A8C)),
        _buildMetricCard('Categorías', _categoriesCount.toString(), Icons.category_outlined, const Color(0xFFF4A261)),
        _buildMetricCard('Sucursales', _branchesCount.toString(), Icons.store_outlined, const Color(0xFF0F4C5C)),
        _buildMetricCard('Stock Total', _totalStock.toString(), Icons.bar_chart_outlined, const Color(0xFF2E8B57)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 26,
                    color: const Color(0xFF12263A),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildActionCard(
          'Productos',
          'Gestionar catálogo',
          Icons.inventory_2_rounded,
          const Color(0xFF1F7A8C),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductosAdminScreen(authService: widget.authService),
            ),
          ).then((_) => _fetchMetrics()),
        ),
        _buildActionCard(
          'Categorías',
          'Organizar secciones',
          Icons.category_rounded,
          const Color(0xFFF4A261),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoriasScreen(authService: widget.authService),
            ),
          ).then((_) => _fetchMetrics()),
        ),
        _buildActionCard(
          'Sucursales',
          'Controlar sedes',
          Icons.store_rounded,
          const Color(0xFF0F4C5C),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SucursalesScreen(authService: widget.authService),
            ),
          ).then((_) => _fetchMetrics()),
        ),
        _buildActionCard(
          'Stocks',
          'Ajustar niveles',
          Icons.swap_horiz_rounded,
          const Color(0xFF2E8B57),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StocksScreen(authService: widget.authService),
            ),
          ).then((_) => _fetchMetrics()),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}