import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/services.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Pantalla inicial: si hay una sesión guardada entra directo a la app,
/// si no, muestra el login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Session?> _future = Services.auth.restore();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Session?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const HomeShell();
      },
    );
  }
}
