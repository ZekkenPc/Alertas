import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/services.dart';

enum _Estado { inicial, consultando, exito, error }

/// Práctica 3: consumo de una URL preasignada.
/// RF01 título, RF02 botón CONSULTAR, RF03 petición HTTP, RF04 mostrar la
/// información, RF05 "Consultando...", RF06 mensaje de error de conexión.
class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  _Estado _estado = _Estado.inicial;
  String _respuesta = '';

  Future<void> _consultar() async {
    setState(() => _estado = _Estado.consultando);
    try {
      final data = await Services.api.info(); // petición HTTP GET
      final texto = const JsonEncoder.withIndent('  ').convert(data);
      if (!mounted) return;
      setState(() {
        _respuesta = texto;
        _estado = _Estado.exito;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _Estado.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consultando = _estado == _Estado.consultando;

    return Scaffold(
      appBar: AppBar(title: const Text('Consulta de información')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Consulta de información',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('URL preasignada:', style: theme.textTheme.bodySmall),
          SelectableText('${ApiConfig.baseUrl}/api/info',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontFamily: 'monospace')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: consultando ? null : _consultar,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('CONSULTAR'),
            ),
          ),
          const SizedBox(height: 24),
          _contenido(theme),
        ],
      ),
    );
  }

  Widget _contenido(ThemeData theme) {
    switch (_estado) {
      case _Estado.inicial:
        return Text('Presiona CONSULTAR para obtener la información.',
            style: theme.textTheme.bodyMedium);
      case _Estado.consultando:
        return const Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Consultando...'),
          ],
        );
      case _Estado.error:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            ApiClient.msgNoInfo, // "No fue posible obtener la información."
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        );
      case _Estado.exito:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF060D18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            _respuesta,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: Color(0xFFAFC0D6),
            ),
          ),
        );
    }
  }
}
