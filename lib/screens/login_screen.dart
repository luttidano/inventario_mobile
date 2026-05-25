import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'productos_screen.dart';
import '../services/api_service.dart';
import 'admin_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final ok = await widget.authService.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        final api = ApiService(widget.authService);
        final me = await api.getMe();
        final isAdmin = me['is_superuser'] == true;

        final next = isAdmin
            ? AdminMenuScreen(authService: widget.authService)
            : ProductosScreen(authService: widget.authService);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => next),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de espera agotado')),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error en _login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexion con el servidor')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Contrasena'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}