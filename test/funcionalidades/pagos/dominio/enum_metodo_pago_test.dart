import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/enum_metodo_pago.dart';

void main() {
  group('MetodoPago', () {
    test('desdeTexto reconoce cada valor valido', () {
      expect(MetodoPago.desdeTexto('efectivo'), MetodoPago.efectivo);
      expect(MetodoPago.desdeTexto('qr_manual'), MetodoPago.qrManual);
      expect(MetodoPago.desdeTexto('pasarela'), MetodoPago.pasarela);
    });

    test(
      'desdeTexto usa efectivo como valor por defecto ante texto desconocido',
      () {
        expect(MetodoPago.desdeTexto('lo-que-sea'), MetodoPago.efectivo);
      },
    );

    test('aTexto es el inverso exacto de desdeTexto para cada valor', () {
      for (final metodo in MetodoPago.values) {
        expect(MetodoPago.desdeTexto(metodo.aTexto()), metodo);
      }
    });
  });
}
