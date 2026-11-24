import 'api_client.dart';
import 'auth_service.dart';
import 'local_db.dart';
import 'monitoring_repository.dart';

/// Punto único de acceso a los servicios de la app.
class Services {
  static final ApiClient api = ApiClient();
  static final AuthService auth = AuthService(api);
  static final LocalDb db = LocalDb();
  static final MonitoringRepository repo =
      MonitoringRepository(api, auth, db);

  /// Cierra sesión: borra el token y el caché local.
  static Future<void> signOut() async {
    await auth.logout();
    try {
      await db.clear();
    } catch (_) {}
  }
}
