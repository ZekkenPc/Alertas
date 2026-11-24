// AUT-02 · Pruebas unitarias del parseo de datos (Incident / Server).
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_alertas_ti/models/models.dart';

import '../helpers/fixtures.dart';

void main() {
  group('Incident.fromJson', () {
    test('entrada válida: convierte todos los campos', () {
      final i = Incident.fromJson(incidentJson());
      expect(i.id, 'INC-1');
      expect(i.title, 'Latencia elevada');
      expect(i.severity, Severity.p2);
      expect(i.logs, ['ERROR a', 'WARN b', 'INFO c']);
      expect(i.detectedAt.toUtc(), DateTime.utc(2026, 10, 5, 8));
    });

    test('campos opcionales nulos o ausentes usan valores por defecto', () {
      final json = incidentJson()
        ..remove('servicio')
        ..remove('descripcion')
        ..remove('estado')
        ..['logs'] = null;
      final i = Incident.fromJson(json);
      expect(i.service, '');
      expect(i.description, '');
      expect(i.status, 'activo');
      expect(i.logs, isEmpty);
    });

    test('campo obligatorio ausente lanza TypeError', () {
      final json = incidentJson()..remove('titulo');
      expect(() => Incident.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fecha con formato inválido lanza FormatException', () {
      final json = incidentJson(detectado: 'ayer por la tarde');
      expect(() => Incident.fromJson(json), throwsFormatException);
    });

    test('toMap y fromMap conservan los datos (ida y vuelta)', () {
      final original = makeIncident();
      final copia = Incident.fromMap(original.toMap(), original.logs);
      expect(copia.id, original.id);
      expect(copia.severity, original.severity);
      expect(copia.detectedAt.isAtSameMomentAs(original.detectedAt), isTrue);
      expect(copia.logs, original.logs);
    });
  });

  group('Severity.parse (valores fuera de rango)', () {
    test('reconoce P1, P2 y P3', () {
      expect(SeverityX.parse('P1'), Severity.p1);
      expect(SeverityX.parse('P2'), Severity.p2);
      expect(SeverityX.parse('P3'), Severity.p3);
    });

    // RIESGO DOCUMENTADO: un valor desconocido se degrada en silencio a P3
    // (el más bajo). Esta prueba fija el comportamiento actual; si se decide
    // corregirlo (p. ej. tratar lo desconocido como P1), se actualiza aquí.
    test('valor desconocido o vacío se interpreta como P3', () {
      expect(SeverityX.parse('P0'), Severity.p3);
      expect(SeverityX.parse(''), Severity.p3);
      expect(SeverityX.parse('p1'), Severity.p3); // distingue mayúsculas
    });
  });

  group('Server.fromJson', () {
    test('entrada válida y cpu decimal se trunca a entero', () {
      final s = Server.fromJson(serverJson()..['cpu'] = 45.9);
      expect(s.name, 'APP-WEB-01');
      expect(s.cpu, 45);
      expect(s.status, ServerStatus.online);
    });

    test('estado desconocido se interpreta como Caído', () {
      final s = Server.fromJson(serverJson()..['estado'] = 'Mantenimiento');
      expect(s.status, ServerStatus.down);
    });

    test('cpu nula lanza TypeError', () {
      final json = serverJson()..['cpu'] = null;
      expect(() => Server.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
