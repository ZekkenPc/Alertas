import 'package:flutter/material.dart';

import '../models/models.dart';

class SeverityBadge extends StatelessWidget {
  final Severity severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final c = severity.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(140)),
      ),
      child: Text(
        severity.label,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
