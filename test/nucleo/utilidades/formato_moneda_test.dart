import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/formato_moneda.dart';

void main() {
  group('formatoMoneda', () {
    test('formatea un monto entero con dos decimales', () {
      expect(formatoMoneda(25.0), 'Bs. 25.00');
    });

    test('formatea un monto con un decimal rellenando con cero', () {
      expect(formatoMoneda(9.5), 'Bs. 9.50');
    });
  });
}
