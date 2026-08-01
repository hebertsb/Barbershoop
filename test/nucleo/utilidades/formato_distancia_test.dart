import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/nucleo/utilidades/formato_distancia.dart';

void main() {
  group('formatoDistancia', () {
    test('metros por debajo de 1000 se muestran en metros redondeados', () {
      expect(formatoDistancia(350), '350 m');
      expect(formatoDistancia(999), '999 m');
    });

    test('1000 metros exactos se muestran en km', () {
      expect(formatoDistancia(1000), '1.0 km');
    });

    test('mas de 1000 metros se muestran en km con 1 decimal', () {
      expect(formatoDistancia(2350), '2.4 km');
      expect(formatoDistancia(15800), '15.8 km');
    });
  });
}
