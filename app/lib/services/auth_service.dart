import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

/// Manejo de la sesión. El token se guarda cifrado (Android Keystore)
/// mediante flutter_secure_storage; nunca en texto plano ni en logs.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kToken = 'token';
  static const _kName = 'nombre';
  static const _kRole = 'rol';

  Session? _session;
  Session? get session => _session;

  /// Recupera la sesión guardada (si existe) al abrir la app.
  Future<Session?> restore() async {
    try {
      final token = await _storage.read(key: _kToken);
      final name = await _storage.read(key: _kName);
      final role = await _storage.read(key: _kRole);
      if (token == null || name == null || role == null) return null;
      _session = Session(token: token, name: name, role: role);
      return _session;
    } catch (_) {
      return null;
    }
  }

  Future<Session> login(String usuario, String clave) async {
    final s = await _api.login(usuario, clave);
    try {
      await _storage.write(key: _kToken, value: s.token);
      await _storage.write(key: _kName, value: s.name);
      await _storage.write(key: _kRole, value: s.role);
    } catch (_) {
      // Si el almacenamiento seguro falla, la sesión vive solo en memoria.
    }
    _session = s;
    return s;
  }

  Future<void> logout() async {
    _session = null;
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kName);
      await _storage.delete(key: _kRole);
    } catch (_) {}
  }
}
