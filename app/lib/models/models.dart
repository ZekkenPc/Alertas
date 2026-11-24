import 'package:flutter/material.dart';

enum Severity { p1, p2, p3 }

extension SeverityX on Severity {
  String get code => switch (this) {
        Severity.p1 => 'P1',
        Severity.p2 => 'P2',
        Severity.p3 => 'P3',
      };

  String get label => switch (this) {
        Severity.p1 => 'Crítico P1',
        Severity.p2 => 'Alto P2',
        Severity.p3 => 'Medio P3',
      };

  Color get color => switch (this) {
        Severity.p1 => const Color(0xFFE5484D),
        Severity.p2 => const Color(0xFFF2994A),
        Severity.p3 => const Color(0xFFE9C74F),
      };

  static Severity parse(String value) => Severity.values.firstWhere(
        (s) => s.code == value,
        orElse: () => Severity.p1,
      );
}

class Incident {
  final String id;
  final String title;
  final String server;
  final String service;
  final Severity severity;
  final String status;
  final DateTime detectedAt;
  final String description;
  final List<String> logs;

  const Incident({
    required this.id,
    required this.title,
    required this.server,
    required this.service,
    required this.severity,
    this.status = 'activo',
    required this.detectedAt,
    required this.description,
    required this.logs,
  });

  /// Construye el incidente desde la respuesta JSON de la API.
  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id'] as String,
        title: json['titulo'] as String,
        server: json['servidor'] as String,
        service: (json['servicio'] as String?) ?? '',
        severity: SeverityX.parse(json['severidad'] as String),
        status: (json['estado'] as String?) ?? 'activo',
        detectedAt: DateTime.parse(json['detectado'] as String).toLocal(),
        description: (json['descripcion'] as String?) ?? '',
        logs: List<String>.from((json['logs'] as List?) ?? const []),
      );

  /// Fila de la tabla `incidentes` (los logs van en `logs_incidente`).
  Map<String, Object?> toMap() => {
        'id': id,
        'titulo': title,
        'servidor': server,
        'servicio': service,
        'severidad': severity.code,
        'estado': status,
        'descripcion': description,
        'detectado_en': detectedAt.toUtc().toIso8601String(),
      };

  factory Incident.fromMap(Map<String, Object?> map, List<String> logs) =>
      Incident(
        id: map['id'] as String,
        title: map['titulo'] as String,
        server: map['servidor'] as String,
        service: (map['servicio'] as String?) ?? '',
        severity: SeverityX.parse(map['severidad'] as String),
        status: (map['estado'] as String?) ?? 'activo',
        detectedAt: DateTime.parse(map['detectado_en'] as String).toLocal(),
        description: (map['descripcion'] as String?) ?? '',
        logs: logs,
      );
}

enum ServerStatus { online, degraded, down }

extension ServerStatusX on ServerStatus {
  String get label => switch (this) {
        ServerStatus.online => 'En línea',
        ServerStatus.degraded => 'Degradado',
        ServerStatus.down => 'Caído',
      };

  Color get color => switch (this) {
        ServerStatus.online => const Color(0xFF3DBE8B),
        ServerStatus.degraded => const Color(0xFFF2994A),
        ServerStatus.down => const Color(0xFFE5484D),
      };

  static ServerStatus parse(String value) => switch (value) {
        'En línea' => ServerStatus.online,
        'Degradado' => ServerStatus.degraded,
        _ => ServerStatus.down,
      };
}

class Server {
  final String name;
  final String ip;
  final String type;
  final ServerStatus status;
  final int cpu;
  final int memory;
  final String uptime;

  const Server({
    required this.name,
    required this.ip,
    required this.type,
    required this.status,
    required this.cpu,
    required this.memory,
    required this.uptime,
  });

  factory Server.fromJson(Map<String, dynamic> json) => Server(
        name: json['nombre'] as String,
        ip: (json['ip'] as String?) ?? '',
        type: (json['tipo'] as String?) ?? '',
        status: ServerStatusX.parse(json['estado'] as String),
        cpu: (json['cpu'] as num).toInt(),
        memory: (json['memoria'] as num).toInt(),
        uptime: (json['uptime'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'nombre': name,
        'ip': ip,
        'tipo': type,
        'estado': status.label,
        'cpu': cpu,
        'memoria': memory,
        'uptime': uptime,
      };

  factory Server.fromMap(Map<String, Object?> map) => Server(
        name: map['nombre'] as String,
        ip: (map['ip'] as String?) ?? '',
        type: (map['tipo'] as String?) ?? '',
        status: ServerStatusX.parse(map['estado'] as String),
        cpu: map['cpu'] as int,
        memory: map['memoria'] as int,
        uptime: (map['uptime'] as String?) ?? '',
      );
}

class MonitoringData {
  final List<Incident> incidents;
  final List<Server> servers;

  const MonitoringData({required this.incidents, required this.servers});

  int countBySeverity(Severity s) =>
      incidents.where((i) => i.severity == s).length;
}
