import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'productos_screen.dart';
import '../services/api_service.dart';
import 'admin_menu_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<Widget> _resolveStart() async {
    final token = await widget.authService.getAccessToken();
    if (token == null) return LoginScreen(authService: widget.authService);

    final api = ApiService(widget.authService);
    try {
      final me = await api.getMe();
      if (me['is_admin'] == true) {
        return AdminMenuScreen(authService: widget.authService);
      }
      return ProductosScreen(authService: widget.authService);
    } catch (_) {
      await widget.authService.logout();
      return LoginScreen(authService: widget.authService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveStart(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F4C5C), Color(0xFF1F7A8C)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'INVENTARIO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}