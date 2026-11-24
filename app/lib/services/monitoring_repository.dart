import '../models/models.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'local_db.dart';

class MonitoringResult {
  final MonitoringData data;

  /// true si los datos vienen del caché local (no hubo conexión).
  final bool fromCache;
  final DateTime? updatedAt;

  const MonitoringResult(this.data, {required this.fromCache, this.updatedAt});
}

/// Fuente de datos de la app: primero la API; si falla la conexión,
/// usa el último caché guardado en SQLite.
class MonitoringRepository {
  MonitoringRepository(this._api, this._auth, this._db);

  final ApiClient _api;
  final AuthService _auth;
  final LocalDb _db;

  Future<MonitoringResult> load() async {
    final token = _auth.session?.token;
    if (token == null) {
      throw const ApiException(ApiClient.msgExpired, unauthorized: true);
    }

    try {
      final incidents = await _api.incidentes(token);
      final servers = await _api.servidores(token);
      final data = MonitoringData(incidents: _sort(incidents), servers: servers);

      try {
        await _db.saveSnapshot(data);
      } catch (_) {
        // Un fallo del caché no debe impedir mostrar datos en vivo.
      }
      return MonitoringResult(data, fromCache: false, updatedAt: DateTime.now());
    } on ApiException catch (e) {
      if (e.unauthorized) rethrow;

      CachedSnapshot? cached;
      try {
        cached = await _db.loadSnapshot();
      } catch (_) {
        cached = null;
      }
      if (cached == null) rethrow;
      return MonitoringResult(
        cached.data,
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }
  }

  /// Más graves primero y, dentro de cada nivel, los más recientes.
  List<Incident> _sort(List<Incident> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      return bySeverity != 0
          ? bySeverity
          : b.detectedAt.compareTo(a.detectedAt);
    });
    return sorted;
  }
}
