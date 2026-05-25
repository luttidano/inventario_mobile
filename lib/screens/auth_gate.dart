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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data!;
      },
    );
  }
}