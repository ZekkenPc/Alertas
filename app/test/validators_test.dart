import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_alertas_ti/utils/validators.dart';

void main() {
  group('Validators.usuario', () {
    test('rechaza vacío o solo espacios', () {
      expect(Validators.usuario(null), isNotNull);
      expect(Validators.usuario(''), isNotNull);
      expect(Validators.usuario('     '), isNotNull);
    });

    test('rechaza longitud excesiva y caracteres no permitidos', () {
      expect(Validators.usuario('a' * 31), isNotNull);
      expect(Validators.usuario('us uario'), isNotNull);
      expect(Validators.usuario('<script>'), isNotNull);
    });

    test('acepta usuarios válidos', () {
      expect(Validators.usuario('coordinador'), isNull);
      expect(Validators.usuario('tecnico.1'), isNull);
      expect(Validators.usuario('  tecnico1  '), isNull);
    });
  });

  group('Validators.clave', () {
    test('rechaza vacía, corta y demasiado larga', () {
      expect(Validators.clave(null), isNotNull);
      expect(Validators.clave(''), isNotNull);
      expect(Validators.clave('1234567'), isNotNull);
      expect(Validators.clave('a' * 65), isNotNull);
    });

    test('acepta de 8 a 64 caracteres', () {
      expect(Validators.clave('12345678'), isNull);
      expect(Validators.clave('Coord#2026'), isNull);
      expect(Validators.clave('a' * 64), isNull);
    });
  });
}
