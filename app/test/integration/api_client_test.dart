// AUT-04 y AUT-05 · Integración ApiClient <-> servicio HTTP (MockClient).
// Se verifica la petición que la app ENVÍA y cómo reacciona a cada respuesta.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sistema_alertas_ti/services/api_client.dart';

import '../helpers/fixtures.dart';

ApiClient clientWith(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(client: MockClient(handler));

Future<ApiException> expectApiError(Future<dynamic> Function() action) async {
  try {
    await action();
  } on ApiException catch (e) {
    return e;
  }
  fail('Se esperaba una ApiException');
}

void main() {
  group('AUT-04 · comunicación correcta con el servicio', () {
    test('login envía POST con JSON y devuelve la sesión', () async {
      late http.Request enviada;
      final api = clientWith((req) async {
        enviada = req;
        return jsonResponse({
          'token': 'tok123',
          'usuario': {'id': 1, 'nombre': 'Coordinador', 'rol': 'coordinador'},
        });
      });

      final s = await api.login('coordinador', 'Coord#2026');

      expect(enviada.method, 'POST');
      expect(enviada.url.path, '/api/auth/login');
      expect(enviada.headers['Content-Type'], contains('application/json'));
      expect(enviada.body, contains('"usuario":"coordinador"'));
      expect(s.token, 'tok123');
      expect(s.role, 'coordinador');
    });

    test('incidentes envía el token Bearer y convierte la lista', () async {
      late http.Request enviada;
      final api = clientWith((req) async {
        enviada = req;
        return jsonResponse({
          'total': 2,
          'incidentes': [incidentJson(id: 'INC-1'), incidentJson(id: 'INC-2')],
        });
      });

      final lista = await api.incidentes('tok123');

      expect(enviada.method, 'GET');
      expect(enviada.url.path, '/api/incidentes');
      expect(enviada.headers['Authorization'], 'Bearer tok123');
      expect(lista.map((i) => i.id), ['INC-1', 'INC-2']);
    });

    test('info (Práctica 3) devuelve el mapa JSON con acentos intactos', () async {
      final api = clientWith(
          (_) async => jsonResponse({'proyecto': 'Sistema de alertas TI', 'nota': 'Información'}));
      final data = await api.info();
      expect(data['proyecto'], 'Sistema de alertas TI');
      expect(data['nota'], 'Información');
    });

    test('credenciales incorrectas (401) devuelven mensaje genérico', () async {
      final api = clientWith((_) async => jsonResponse({'error': 'x'}, 401));
      final e = await expectApiError(() => api.login('coordinador', 'MalaClave1'));
      expect(e.message, ApiClient.msgBadLogin);
      expect(e.unauthorized, isTrue);
      expect(e.offline, isFalse);
    });

    test('token rechazado (401) en incidentes indica sesión expirada', () async {
      final api = clientWith((_) async => jsonResponse({'error': 'x'}, 401));
      final e = await expectApiError(() => api.incidentes('viejo'));
      expect(e.message, ApiClient.msgExpired);
      expect(e.unauthorized, isTrue);
    });
  });

  group('AUT-05 · el servidor no responde o responde mal', () {
    test('sin red (SocketException) en login muestra mensaje de conexión', () async {
      final api = clientWith((_) async => throw const SocketException('sin red'));
      final e = await expectApiError(() => api.login('coordinador', 'Coord#2026'));
      expect(e.message, ApiClient.msgNoLogin);
      expect(e.offline, isTrue);
    });

    test('sin red en info muestra "No fue posible obtener la información."', () async {
      final api = clientWith((_) async => throw http.ClientException('caído'));
      final e = await expectApiError(() => api.info());
      expect(e.message, ApiClient.msgNoInfo);
      expect(e.offline, isTrue);
    });

    test('error 500 no filtra detalles técnicos', () async {
      final api = clientWith((_) async => jsonResponse({'error': 'stack trace secreto'}, 500));
      final e = await expectApiError(() => api.servidores('tok'));
      expect(e.message, ApiClient.msgNoInfo);
      expect(e.message, isNot(contains('stack')));
      expect(e.offline, isFalse);
    });

    test('respuesta 200 que no es JSON se trata como error controlado', () async {
      final api = clientWith((_) async => http.Response('<html>proxy</html>', 200));
      final e = await expectApiError(() => api.info());
      expect(e.message, ApiClient.msgNoInfo);
    });

    test('login sin token en la respuesta se trata como error controlado', () async {
      final api = clientWith((_) async => jsonResponse({'usuario': {}}));
      final e = await expectApiError(() => api.login('coordinador', 'Coord#2026'));
      expect(e.message, ApiClient.msgNoLogin);
    });
  });
}
