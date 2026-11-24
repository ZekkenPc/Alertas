import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/monitoring_repository.dart';
import '../services/services.dart';
import '../utils/format.dart';
import 'dashboard_screen.dart';
import 'incidents_screen.dart';
import 'infrastructure_screen.dart';

/// Contenedor principal con barra de navegación inferior.
/// Descarga los datos de la API, los consulta de nuevo cada cierto tiempo
/// (casi tiempo real) y usa el caché local si no hay conexión.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _repo = Services.repo;
  Timer? _timer;

  MonitoringResult? _result;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Set<String>? _knownIds;

  int _index = 0;
  Severity? _filter;

  static const _titles = ['Panel de guardia', 'Incidentes', 'Infraestructura'];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      ApiConfig.pollInterval,
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _repo.load();
      if (!mounted) return;
      _notifyNew(result);
      setState(() {
        _result = result;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        await _logout(expired: true);
        return;
      }
      setState(() {
        _loading = false;
        if (_result == null) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_result == null) _error = ApiClient.msgNoInfo;
      });
    } finally {
      _busy = false;
    }
  }

  /// Avisa cuando llegan incidentes que antes no estaban en la lista.
  void _notifyNew(MonitoringResult result) {
    if (result.fromCache) return;
    final ids = result.data.incidents.map((i) => i.id).toSet();
    final known = _knownIds;
    _knownIds = ids;
    if (known == null) return;

    final fresh =
        result.data.incidents.where((i) => !known.contains(i.id)).toList();
    if (fresh.isEmpty) return;
    fresh.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    final top = fresh.first;
    final extra = fresh.length - 1;
    final text = extra > 0
        ? 'Nuevo incidente ${top.severity.code}: ${top.title} (+$extra más)'
        : 'Nuevo incidente ${top.severity.code}: ${top.title}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'VER',
          onPressed: () =>
              Navigator.pushNamed(context, '/incidente', arguments: top),
        ),
      ),
    );
  }

  Future<void> _logout({bool expired = false}) async {
    _timer?.cancel();
    await Services.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
      arguments: expired ? ApiClient.msgExpired : null,
    );
  }

  void _openIncidents(Severity? severity) => setState(() {
        _filter = severity;
        _index = 1;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'consulta') {
                Navigator.pushNamed(context, '/consulta');
              } else if (value == 'salir') {
                _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'consulta',
                child: Text('Consulta de información'),
              ),
              PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Panel'),
          NavigationDestination(
              icon: Icon(Icons.notifications_active_outlined),
              selectedIcon: Icon(Icons.notifications_active),
              label: 'Incidentes'),
          NavigationDestination(
              icon: Icon(Icons.dns_outlined),
              selectedIcon: Icon(Icons.dns),
              label: 'Servidores'),
        ],
      ),
    );
  }

  Widget _body() {
    final result = _result;
    if (result == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? ApiClient.msgNoInfo, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _refresh,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final data = result.data;
    final session = Services.auth.session;
    final greeting =
        session == null ? null : 'Hola, ${session.name} · ${session.role}';

    return Column(
      children: [
        if (result.fromCache) _OfflineBanner(updatedAt: result.updatedAt),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: [
              DashboardScreen(
                data: data,
                greeting: greeting,
                onSeverityTap: _openIncidents,
              ),
              IncidentsScreen(
                data: data,
                filter: _filter,
                onFilterChanged: (s) => setState(() => _filter = s),
              ),
              InfrastructureScreen(data: data),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final DateTime? updatedAt;
  const _OfflineBanner({required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final when = updatedAt == null ? '' : ' (${formatDateTime(updatedAt!)})';
    return Container(
      width: double.infinity,
      color: const Color(0xFFF2994A).withAlpha(50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Color(0xFFF2994A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión con el servidor. Mostrando datos guardados$when.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
