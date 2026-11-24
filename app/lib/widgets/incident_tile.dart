import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/format.dart';
import 'severity_badge.dart';

class IncidentTile extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;
  const IncidentTile({super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: incident.severity.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SeverityBadge(severity: incident.severity),
                          const Spacer(),
                          Text(incident.id, style: theme.textTheme.labelMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        incident.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${incident.server} • ${incident.service}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detectado ${formatDateTime(incident.detectedAt)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
