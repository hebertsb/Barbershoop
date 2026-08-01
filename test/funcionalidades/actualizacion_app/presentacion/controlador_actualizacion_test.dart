import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/actualizacion_app/presentacion/controladores/controlador_actualizacion.dart';

void main() {
  group('versionInstaladaDesactualizada', () {
    test('devuelve false cuando las versiones son iguales', () {
      expect(versionInstaladaDesactualizada('1.2.3', '1.2.3'), isFalse);
    });

    test('devuelve false cuando la instalada es mayor que la remota', () {
      expect(versionInstaladaDesactualizada('2.0.0', '1.9.9'), isFalse);
      expect(versionInstaladaDesactualizada('1.10.0', '1.9.0'), isFalse);
    });

    test('devuelve true cuando la instalada es menor que la remota', () {
      expect(versionInstaladaDesactualizada('1.0.0', '1.0.1'), isTrue);
      expect(versionInstaladaDesactualizada('1.9.0', '1.10.0'), isTrue);
    });

    test(
      'completa con 0 los componentes faltantes cuando difiere la cantidad',
      () {
        expect(versionInstaladaDesactualizada('1.0', '1.0.0'), isFalse);
        expect(versionInstaladaDesactualizada('1.0.0', '1.0'), isFalse);
        expect(versionInstaladaDesactualizada('1.0', '1.0.1'), isTrue);
        expect(versionInstaladaDesactualizada('1.1', '1.0.9'), isFalse);
      },
    );
  });
}
