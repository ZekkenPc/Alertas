import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

/// Error de la API con un mensaje SEGURO para mostrar al usuario.
/// Nunca contiene detalles técnicos, rutas ni datos sensibles.
class ApiException implements Exception {
  final String message;
  final bool unauthorized;
  final bool offline;

  const ApiException(
    this.message, {
    this.unauthorized = false,
    this.offline = false,
  });

  @override
  String toString() => message;
}

class Session {
  final String token;
  final String name;
  final String role;
  const Session({required this.token, required this.name, required this.role});
}

/// Cliente HTTP de la API REST. Es la única clase que conoce las URLs.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String msgNoInfo = 'No fue posible obtener la información.';
  static const String msgNoLogin =
      'No fue posible conectar con el servidor. Revisa tu conexión.';
  static const String msgBadLogin = 'Usuario o contraseña incorrectos.';
  static const String msgExpired = 'Tu sesión expiró. Inicia sesión de nuevo.';

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Ejecuta la petición, controla errores de conexión y decodifica el JSON.
  Future<dynamic> _send(
    Future<http.Response> Function() call, {
    String offlineMessage = msgNoInfo,
    String unauthorizedMessage = msgExpired,
  }) async {
    http.Response resp;
    try {
      resp = await call().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException(offlineMessage, offline: true);
    } catch (_) {
      // Sin red, servidor apagado, URL incorrecta, etc.
      throw ApiException(offlineMessage, offline: true);
    }

    if (resp.statusCode == 401) {
      throw ApiException(unauthorizedMessage, unauthorized: true);
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(offlineMessage);
    }
    try {
      return jsonDecode(utf8.decode(resp.bodyBytes));
    } catch (_) {
      throw ApiException(offlineMessage);
    }
  }

  /// Práctica 3: consulta pública a la URL preasignada.
  Future<Map<String, dynamic>> info() async {
    final data = await _send(() => _client.get(_uri('/api/info'), headers: _headers()));
    if (data is! Map<String, dynamic>) throw const ApiException(msgNoInfo);
    return data;
  }

  Future<Session> login(String usuario, String clave) async {
    final data = await _send(
      () => _client.post(
        _uri('/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'usuario': usuario, 'clave': clave}),
      ),
      offlineMessage: msgNoLogin,
      unauthorizedMessage: msgBadLogin,
    );
    try {
      final map = data as Map<String, dynamic>;
      final user = map['usuario'] as Map<String, dynamic>;
      return Session(
        token: map['token'] as String,
        name: user['nombre'] as String,
        role: user['rol'] as String,
      );
    } catch (_) {
      throw const ApiException(msgNoLogin);
    }
  }

  Future<List<Incident>> incidentes(String token) async {
    final data = await _send(
      () => _client.get(_uri('/api/incidentes'), headers: _headers(token)),
    );
    try {
      final list = (data as Map<String, dynamic>)['incidentes'] as List;
      return list
          .map((e) => Incident.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ApiException(msgNoInfo);
    }
  }

  Future<List<Server>> servidores(String token) async {
    final data = await _send(
      () => _client.get(_uri('/api/servidores'), headers: _headers(token)),
    );
    try {
      final list = (data as Map<String, dynamic>)['servidores'] as List;
      return list
          .map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ApiException(msgNoInfo);
    }
  }
}
