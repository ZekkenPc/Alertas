import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/incident_tile.dart';
import '../widgets/severity_badge.dart';

class DashboardScreen extends StatelessWidget {
  final MonitoringData data;
  final void Function(Severity?) onSeverityTap;
  final String? greeting;
  const DashboardScreen({
    super.key,
    required this.data,
    required this.onSeverityTap,
    this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.incidents.length;
    final online =
        data.servers.where((s) => s.status == ServerStatus.online).length;
    final urgent =
        data.incidents.where((i) => i.severity == Severity.p1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (greeting != null) ...[
          Text(greeting!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        Text('Incidentes activos', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text('$total',
            style: theme.textTheme.displayMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('$online de ${data.servers.length} servidores en línea',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final s in Severity.values) ...[
              Expanded(
                child: _SeverityCard(
                  severity: s,
                  count: data.countBySeverity(s),
                  onTap: () => onSeverityTap(s),
                ),
              ),
              if (s != Severity.p3) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Requieren atención inmediata',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            const SeverityBadge(severity: Severity.p1),
          ],
        ),
        const SizedBox(height: 12),
        if (urgent.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay incidentes críticos activos.'),
            ),
          )
        else
          for (final i in urgent)
            IncidentTile(
              incident: i,
              onTap: () =>
                  Navigator.pushNamed(context, '/incidente', arguments: i),
            ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => onSeverityTap(null),
          child: const Text('Ver todos los incidentes'),
        ),
      ],
    );
  }
}

class _SeverityCard extends StatelessWidget {
  final Severity severity;
  final int count;
  final VoidCallback onTap;
  const _SeverityCard({
    required this.severity,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = severity.color;
    return Card(
      color: c.withAlpha(28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.withAlpha(120)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count',
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(color: c, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(severity.label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
