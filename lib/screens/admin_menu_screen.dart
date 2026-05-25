import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'categorias_screen.dart';
import 'productos_screen.dart';
import 'sucursales_screen.dart';
import 'stocks_screen.dart';
import 'login_screen.dart';
import 'productos_admin_screen.dart';


class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key, required this.authService});
  final AuthService authService;

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(authService: authService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Productos'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductosAdminScreen(authService: authService)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorias'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoriasScreen(authService: authService)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Sucursales'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SucursalesScreen(authService: authService)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Stocks'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StocksScreen(authService: authService)),
            ),
          ),
        ],
      ),
    );
  }
}