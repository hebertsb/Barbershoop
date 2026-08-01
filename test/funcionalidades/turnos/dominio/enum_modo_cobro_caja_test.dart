import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_modo_cobro_caja.dart';

void main() {
  group('ModoCobroCaja', () {
    test('desdeTexto reconoce cada valor valido', () {
      expect(ModoCobroCaja.desdeTexto('al_final'), ModoCobroCaja.alFinal);
      expect(ModoCobroCaja.desdeTexto('al_llegar'), ModoCobroCaja.alLlegar);
    });

    test(
      'desdeTexto usa al_final como valor por defecto ante texto desconocido',
      () {
        expect(ModoCobroCaja.desdeTexto('lo-que-sea'), ModoCobroCaja.alFinal);
      },
    );

    test('aTexto es el inverso exacto de desdeTexto para cada valor', () {
      for (final modo in ModoCobroCaja.values) {
        expect(ModoCobroCaja.desdeTexto(modo.aTexto()), modo);
      }
    });
  });
}
