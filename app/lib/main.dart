import 'package:flutter/material.dart';

import 'models/models.dart';
import 'screens/auth_gate.dart';
import 'screens/consulta_screen.dart';
import 'screens/home_shell.dart';
import 'screens/incident_detail_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlertasTiApp());
}

class AlertasTiApp extends StatelessWidget {
  const AlertasTiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0E1A2B);
    const surface = Color(0xFF16263B);

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4C8DFF),
      brightness: Brightness.dark,
    ).copyWith(surface: bg);

    return MaterialApp(
      title: 'Alertas TI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(notice: settings.arguments as String?),
              settings: settings,
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomeShell(),
              settings: settings,
            );
          case '/incidente':
            final incident = settings.arguments as Incident;
            return MaterialPageRoute(
              builder: (_) => IncidentDetailScreen(incident: incident),
              settings: settings,
            );
          case '/consulta':
            return MaterialPageRoute(
              builder: (_) => const ConsultaScreen(),
              settings: settings,
            );
          case '/':
          default:
            return MaterialPageRoute(
              builder: (_) => const AuthGate(),
              settings: settings,
            );
        }
      },
    );
  }
}
