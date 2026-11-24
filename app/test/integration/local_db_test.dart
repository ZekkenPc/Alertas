// AUT-06 · Persistencia: LocalDb (SQLite) con base real en un directorio temporal.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_alertas_ti/models/models.dart';
import 'package:sistema_alertas_ti/services/local_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tmp;
  late LocalDb db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('alertas_db_');
    await databaseFactory.setDatabasesPath(tmp.path);
    db = LocalDb();
  });

  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('caché vacío: loadSnapshot devuelve null', () async {
    expect(await db.loadSnapshot(), isNull);
  });

  test('guardar y leer conserva incidentes, servidores y orden de logs', () async {
    final data = MonitoringData(
      incidents: [
        makeIncident(id: 'INC-1', severity: Severity.p1, logs: ['uno', 'dos', 'tres']),
        makeIncident(id: 'INC-2', severity: Severity.p3, logs: const []),
      ],
      servers: [makeServer(name: 'APP-WEB-01'), makeServer(name: 'DB-01')],
    );

    await db.saveSnapshot(data);
    final leido = await db.loadSnapshot();

    expect(leido, isNotNull);
    expect(leido!.data.incidents.length, 2);
    expect(leido.data.servers.length, 2);
    final inc1 = leido.data.incidents.firstWhere((i) => i.id == 'INC-1');
    expect(inc1.severity, Severity.p1);
    expect(inc1.logs, ['uno', 'dos', 'tres']);
    final inc2 = leido.data.incidents.firstWhere((i) => i.id == 'INC-2');
    expect(inc2.logs, isEmpty);
  });

  test('un segundo guardado reemplaza el caché (sin duplicados)', () async {
    await db.saveSnapshot(MonitoringData(
      incidents: [makeIncident(id: 'A'), makeIncident(id: 'B'), makeIncident(id: 'C')],
      servers: [makeServer()],
    ));
    await db.saveSnapshot(MonitoringData(
      incidents: [makeIncident(id: 'Z', logs: ['solo'])],
      servers: [makeServer()],
    ));

    final leido = await db.loadSnapshot();
    expect(leido!.data.incidents.map((i) => i.id), ['Z']);
    expect(leido.data.incidents.single.logs, ['solo']);
    expect(leido.data.servers.length, 1);
  });

  test('guarda la fecha de última sincronización', () async {
    await db.saveSnapshot(MonitoringData(incidents: [makeIncident()], servers: const []));
    final leido = await db.loadSnapshot();
    expect(leido!.updatedAt, isNotNull);
    expect(DateTime.now().difference(leido.updatedAt!).inMinutes.abs() < 2, isTrue);
  });

  test('clear() borra todo el caché (cierre de sesión)', () async {
    await db.saveSnapshot(MonitoringData(
      incidents: [makeIncident()],
      servers: [makeServer()],
    ));
    await db.clear();
    expect(await db.loadSnapshot(), isNull);
  });
}
