import 'package:flutter/material.dart';

import '../models/models.dart';

class InfrastructureScreen extends StatelessWidget {
  final MonitoringData data;
  const InfrastructureScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int count(ServerStatus s) =>
        data.servers.where((e) => e.status == s).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final s in ServerStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(color: s.color),
                  const SizedBox(width: 6),
                  Text('${count(s)} ${s.label.toLowerCase()}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final server in data.servers) _ServerCard(server: server),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  final Server server;
  const _ServerCard({required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDown = server.status == ServerStatus.down;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Dot(color: server.status.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(server.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(server.status.label,
                    style: TextStyle(
                        color: server.status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${server.type} • ${server.ip}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (isDown)
              Text('Sin respuesta del servidor',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: server.status.color))
            else ...[
              _Meter(label: 'CPU', value: server.cpu),
              const SizedBox(height: 8),
              _Meter(label: 'Memoria', value: server.memory),
              const SizedBox(height: 8),
              Text('Tiempo activo: ${server.uptime}',
                  style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  final String label;
  final int value;
  const _Meter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 90
        ? const Color(0xFFE5484D)
        : value >= 75
            ? const Color(0xFFF2994A)
            : const Color(0xFF3DBE8B);
    return Row(
      children: [
        SizedBox(
            width: 64,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(35),
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text('$value%',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
