import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class CachedSnapshot {
  final MonitoringData data;
  final DateTime? updatedAt;
  const CachedSnapshot(this.data, this.updatedAt);
}

/// Almacenamiento estructurado local (SQLite con sqflite).
/// Funciona como caché: guarda la última respuesta de la API para poder
/// mostrar incidentes y servidores aunque no haya conexión.
///
/// Tablas: incidentes, logs_incidente (1:N), servidores y metadatos.
class LocalDb {
  static const _dbName = 'alertas_ti.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE incidentes (
            id TEXT PRIMARY KEY,
            titulo TEXT NOT NULL,
            servidor TEXT NOT NULL,
            servicio TEXT,
            severidad TEXT NOT NULL CHECK (severidad IN ('P1','P2','P3')),
            estado TEXT NOT NULL DEFAULT 'activo',
            descripcion TEXT,
            detectado_en TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE logs_incidente (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            incidente_id TEXT NOT NULL
              REFERENCES incidentes(id) ON DELETE CASCADE,
            orden INTEGER NOT NULL,
            linea TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE servidores (
            nombre TEXT PRIMARY KEY,
            ip TEXT,
            tipo TEXT,
            estado TEXT NOT NULL,
            cpu INTEGER NOT NULL,
            memoria INTEGER NOT NULL,
            uptime TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE metadatos (
            clave TEXT PRIMARY KEY,
            valor TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_incidentes_sev ON incidentes(severidad, detectado_en)',
        );
        await db.execute(
          'CREATE INDEX idx_logs_incidente ON logs_incidente(incidente_id, orden)',
        );
      },
    );
  }

  /// Reemplaza el contenido del caché por la última respuesta de la API.
  Future<void> saveSnapshot(MonitoringData data) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('logs_incidente');
      await txn.delete('incidentes');
      await txn.delete('servidores');

      final batch = txn.batch();
      for (final i in data.incidents) {
        batch.insert('incidentes', i.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        for (var n = 0; n < i.logs.length; n++) {
          batch.insert('logs_incidente', {
            'incidente_id': i.id,
            'orden': n,
            'linea': i.logs[n],
          });
        }
      }
      for (final s in data.servers) {
        batch.insert('servidores', s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.insert(
        'metadatos',
        {
          'clave': 'ultima_sincronizacion',
          'valor': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    });
  }

  /// Lee el último caché guardado. Devuelve null si está vacío.
  Future<CachedSnapshot?> loadSnapshot() async {
    final db = await _database;
    final incidentRows = await db.query('incidentes');
    final serverRows = await db.query('servidores');
    if (incidentRows.isEmpty && serverRows.isEmpty) return null;

    final logRows =
        await db.query('logs_incidente', orderBy: 'incidente_id, orden');
    final logs = <String, List<String>>{};
    for (final r in logRows) {
      logs
          .putIfAbsent(r['incidente_id'] as String, () => <String>[])
          .add(r['linea'] as String);
    }

    final incidents = incidentRows
        .map((r) => Incident.fromMap(r, logs[r['id'] as String] ?? <String>[]))
        .toList();
    final servers = serverRows.map(Server.fromMap).toList();

    final meta = await db.query(
      'metadatos',
      where: 'clave = ?',
      whereArgs: ['ultima_sincronizacion'],
    );
    final updatedAt = meta.isEmpty
        ? null
        : DateTime.tryParse(meta.first['valor'] as String)?.toLocal();

    return CachedSnapshot(
      MonitoringData(incidents: incidents, servers: servers),
      updatedAt,
    );
  }

  /// Borra todo el caché (se usa al cerrar sesión).
  Future<void> clear() async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('logs_incidente');
      await txn.delete('incidentes');
      await txn.delete('servidores');
      await txn.delete('metadatos');
    });
  }
}
