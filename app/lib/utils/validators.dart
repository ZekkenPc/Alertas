/// Validaciones de entrada del login (código seguro).
/// Los mensajes son claros para el usuario pero no revelan datos sensibles.
class Validators {
  static const int maxUsuario = 30;
  static const int minClave = 8;
  static const int maxClave = 64;

  static final RegExp _usuarioValido = RegExp(r'^[A-Za-z0-9._-]+$');

  static String? usuario(String? value) {
    final v = value?.trim() ?? '';
    // Rechaza vacío y usuarios formados solo por espacios.
    if (v.isEmpty) return 'Ingresa tu usuario.';
    // Rechaza entradas que superen la longitud definida.
    if (v.length > maxUsuario) return 'El usuario es demasiado largo.';
    if (!_usuarioValido.hasMatch(v)) {
      return 'El usuario contiene caracteres no permitidos.';
    }
    return null;
  }

  static String? clave(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    if (v.length < minClave) {
      return 'La contraseña debe tener al menos $minClave caracteres.';
    }
    if (v.length > maxClave) return 'La contraseña es demasiado larga.';
    return null;
  }
}
