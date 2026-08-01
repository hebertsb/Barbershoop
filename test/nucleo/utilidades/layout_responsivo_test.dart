import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/layout_responsivo.dart';

void main() {
  group('esPantallaAncha', () {
    test('por debajo del umbral es angosta', () {
      expect(esPantallaAncha(500), isFalse);
      expect(esPantallaAncha(839), isFalse);
    });

    test('en el umbral exacto o por encima es ancha', () {
      expect(esPantallaAncha(840), isTrue);
      expect(esPantallaAncha(1200), isTrue);
    });
  });

  group('calcularColumnas', () {
    test('un ancho angosto da el minimo de columnas', () {
      expect(
        calcularColumnas(300, anchoTarjeta: 200, minimo: 2, maximo: 4),
        2,
      );
    });

    test('un ancho que entra exacto para 3 tarjetas da 3 columnas', () {
      expect(
        calcularColumnas(620, anchoTarjeta: 200, minimo: 2, maximo: 4),
        3,
      );
    });

    test('un ancho muy grande se limita al maximo', () {
      expect(
        calcularColumnas(5000, anchoTarjeta: 200, minimo: 2, maximo: 4),
        4,
      );
    });

    test('usa los valores por defecto si no se especifican', () {
      expect(calcularColumnas(300), 2);
      expect(calcularColumnas(5000), 4);
    });
  });
}
