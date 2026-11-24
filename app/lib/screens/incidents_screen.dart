import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/incident_tile.dart';

class IncidentsScreen extends StatelessWidget {
  final MonitoringData data;
  final Severity? filter;
  final ValueChanged<Severity?> onFilterChanged;
  const IncidentsScreen({
    super.key,
    required this.data,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = filter == null
        ? data.incidents
        : data.incidents.where((i) => i.severity == filter).toList();

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('Todos (${data.incidents.length})', null),
              for (final s in Severity.values)
                _chip('${s.code} (${data.countBySeverity(s)})', s),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No hay incidentes con este filtro.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => IncidentTile(
                    incident: items[index],
                    onTap: () => Navigator.pushNamed(context, '/incidente',
                        arguments: items[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, Severity? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: filter == value,
          onSelected: (_) => onFilterChanged(value),
        ),
      );
}
