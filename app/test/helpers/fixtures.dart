import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sistema_alertas_ti/models/models.dart';

/// Respuesta JSON en UTF-8 (acentos incluidos) para los MockClient.
http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> incidentJson({
  String id = 'INC-1',
  String severidad = 'P2',
  String detectado = '2026-10-05T08:00:00.000Z',
  List<String> logs = const ['ERROR a', 'WARN b', 'INFO c'],
}) =>
    {
      'id': id,
      'titulo': 'Latencia elevada',
      'servidor': 'APP-WEB-01',
      'servicio': 'web',
      'severidad': severidad,
      'estado': 'activo',
      'detectado': detectado,
      'descripcion': 'Descripción de prueba',
      'logs': logs,
    };

Map<String, dynamic> serverJson({String nombre = 'APP-WEB-01'}) => {
      'nombre': nombre,
      'ip': '10.0.0.1',
      'tipo': 'Web',
      'estado': 'En línea',
      'cpu': 40,
      'memoria': 55,
      'uptime': '12d',
    };

Incident makeIncident({
  String id = 'INC-1',
  Severity severity = Severity.p2,
  DateTime? detectedAt,
  List<String> logs = const ['ERROR a', 'WARN b', 'INFO c'],
}) =>
    Incident(
      id: id,
      title: 'Latencia elevada',
      server: 'APP-WEB-01',
      service: 'web',
      severity: severity,
      detectedAt: detectedAt ?? DateTime.utc(2026, 10, 5, 8),
      description: 'Descripción de prueba',
      logs: logs,
    );

Server makeServer({String name = 'APP-WEB-01'}) => Server(
      name: name,
      ip: '10.0.0.1',
      type: 'Web',
      status: ServerStatus.online,
      cpu: 40,
      memory: 55,
      uptime: '12d',
    );
