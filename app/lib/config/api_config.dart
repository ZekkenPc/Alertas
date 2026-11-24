/// Configuración de la conexión con la API REST.
///
/// La URL está separada de la lógica de la app: para cambiarla basta con
/// editar este archivo o ejecutar con --dart-define, por ejemplo:
///   flutter run --dart-define=API_URL=http://192.168.1.50:3000
class ApiConfig {
  /// Emulador Android: 10.0.2.2 apunta al localhost de la PC.
  /// Teléfono físico: usar la IP de la PC en la red local.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Tiempo máximo de espera de cada petición.
  static const Duration timeout = Duration(seconds: 10);

  /// Cada cuánto se consultan incidentes nuevos (tiempo casi real).
  static const Duration pollInterval = Duration(seconds: 15);
}
