// AUT-05 / AUT-06 · Integración ApiClient + AuthService + LocalDb + Repository.
// Verifica el flujo "API -> caché -> sin conexión -> datos del caché".
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_alertas_ti/services/api_client.dart';
import 'package:sistema_alertas_ti/services/auth_service.dart';
import 'package:sistema_alertas_ti/services/local_db.dart';
import 'package:sistema_alertas_ti/services/monitoring_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late bool online;
  late bool tokenRechazado;
  late MonitoringRepository repo;
  late AuthService auth;

  Future<http.Response> servidorFalso(http.Request req) async {
    if (req.url.path == '/api/auth/login') {
      return jsonResponse({
        'token': 'tok',
        'usuario': {'id': 1, 'nombre': 'Tecnico', 'rol': 'tecnico'},
      });
    }
    if (!online) throw const SocketException('servidor apagado');
    if (tokenRechazado) return jsonResponse({'error': 'No autorizado'}, 401);
    if (req.url.path == '/api/incidentes') {
      return jsonResponse({
        'incidentes': [
          incidentJson(id: 'INC-P3', severidad: 'P3', detectado: '2026-10-05T10:00:00Z'),
          incidentJson(id: 'INC-P1-VIEJO', severidad: 'P1', detectado: '2026-10-05T08:00:00Z'),
          incidentJson(id: 'INC-P1-NUEVO', severidad: 'P1', detectado: '2026-10-05T09:00:00Z'),
          incidentJson(id: 'INC-P2', severidad: 'P2', detectado: '2026-10-05T07:00:00Z'),
        ],
      });
    }
    if (req.url.path == '/api/servidores') {
      return jsonResponse({'servidores': [serverJson()]});
    }
    return jsonResponse({'error': 'No encontrado'}, 404);
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // El almacenamiento seguro no existe en la VM de pruebas: se simula.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  setUp(() async {
    online = true;
    tokenRechazado = false;
    tmp = await Directory.systemTemp.createTemp('alertas_repo_');
    await databaseFactory.setDatabasesPath(tmp.path);

    final api = ApiClient(client: MockClient(servidorFalso));
    auth = AuthService(api);
    repo = MonitoringRepository(api, auth, LocalDb());
  });

  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('sin sesión iniciada lanza ApiException de sesión expirada', () async {
    try {
      await repo.load();
      fail('Se esperaba una ApiException');
    } on ApiException catch (e) {
      expect(e.unauthorized, isTrue);
      expect(e.message, ApiClient.msgExpired);
    }
  });

  test('con conexión: datos en vivo ordenados por severidad y fecha', () async {
    await auth.login('tecnico1', 'Tecnico#2026');
    final r = await repo.load();

    expect(r.fromCache, isFalse);
    expect(r.data.incidents.map((i) => i.id),
        ['INC-P1-NUEVO', 'INC-P1-VIEJO', 'INC-P2', 'INC-P3']);
    expect(r.data.servers.length, 1);
  });

  test('sin conexión: devuelve el último caché guardado', () async {
    await auth.login('tecnico1', 'Tecnico#2026');
    final enVivo = await repo.load();

    online = false;
    final r = await repo.load();

    expect(r.fromCache, isTrue);
    expect(r.updatedAt, isNotNull);
    expect(r.data.incidents.length, enVivo.data.incidents.length);
    expect(r.data.incidents.first.logs, ['ERROR a', 'WARN b', 'INFO c']);
  });

  test('sin conexión y sin caché: propaga el error de conexión', () async {
    await auth.login('tecnico1', 'Tecnico#2026');
    online = false;
    try {
      await repo.load();
      fail('Se esperaba una ApiException');
    } on ApiException catch (e) {
      expect(e.offline, isTrue);
      expect(e.unauthorized, isFalse);
    }
  });

  test('token rechazado (401) no usa el caché: obliga a iniciar sesión', () async {
    await auth.login('tecnico1', 'Tecnico#2026');
    await repo.load(); // llena el caché

    tokenRechazado = true;
    try {
      await repo.load();
      fail('Se esperaba una ApiException');
    } on ApiException catch (e) {
      expect(e.unauthorized, isTrue);
    }
  });
}
