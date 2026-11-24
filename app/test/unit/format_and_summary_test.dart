// AUT-03 · Pruebas unitarias de formato de fecha y conteo por severidad.
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_alertas_ti/models/models.dart';
import 'package:sistema_alertas_ti/utils/format.dart';

import '../helpers/fixtures.dart';

void main() {
  group('formatDateTime', () {
    test('rellena con ceros día, hora y minuto', () {
      expect(formatDateTime(DateTime(2026, 10, 5, 8, 7)), '05 oct 2026, 08:07');
    });

    test('límites del año: enero y diciembre', () {
      expect(formatDateTime(DateTime(2026, 1, 31, 23, 59)), '31 ene 2026, 23:59');
      expect(formatDateTime(DateTime(2026, 12, 1, 0, 0)), '01 dic 2026, 00:00');
    });
  });

  group('MonitoringData.countBySeverity', () {
    test('cuenta cada nivel de severidad', () {
      final data = MonitoringData(
        incidents: [
          makeIncident(id: 'A', severity: Severity.p1),
          makeIncident(id: 'B', severity: Severity.p1),
          makeIncident(id: 'C', severity: Severity.p3),
        ],
        servers: const [],
      );
      expect(data.countBySeverity(Severity.p1), 2);
      expect(data.countBySeverity(Severity.p2), 0);
      expect(data.countBySeverity(Severity.p3), 1);
    });

    test('lista vacía devuelve 0 en todos los niveles', () {
      const data = MonitoringData(incidents: [], servers: []);
      for (final s in Severity.values) {
        expect(data.countBySeverity(s), 0);
      }
    });
  });

  test('Severity.code y label son consistentes', () {
    expect(Severity.p1.code, 'P1');
    expect(Severity.p1.label, contains('P1'));
    expect(Severity.p3.label, contains('P3'));
  });
}
