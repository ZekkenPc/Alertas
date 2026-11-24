import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/severity_badge.dart';

class IncidentDetailScreen extends StatelessWidget {
  final Incident incident;
  const IncidentDetailScreen({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(incident.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SeverityBadge(severity: incident.severity),
          ),
          const SizedBox(height: 12),
          Text(incident.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(Icons.dns_outlined, 'Servidor', incident.server),
                  const Divider(height: 24),
                  _InfoRow(Icons.miscellaneous_services_outlined, 'Servicio',
                      incident.service),
                  const Divider(height: 24),
                  _InfoRow(Icons.schedule, 'Hora de detección',
                      formatDateTime(incident.detectedAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Descripción',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(incident.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('Logs de error',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF060D18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in incident.logs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: _logColor(line),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _logColor(String line) {
    if (line.contains('FATAL') ||
        line.contains('ERROR') ||
        line.contains('ALERT')) {
      return const Color(0xFFFF8A8E);
    }
    if (line.contains('WARN')) return const Color(0xFFF2C46D);
    return const Color(0xFFAFC0D6);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
