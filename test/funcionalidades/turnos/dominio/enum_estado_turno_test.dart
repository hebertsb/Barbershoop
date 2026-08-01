import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_estado_turno.dart';

void main() {
  group('EstadoTurno', () {
    test('desdeTexto reconoce cada valor valido', () {
      expect(EstadoTurno.desdeTexto('esperando'), EstadoTurno.esperando);
      expect(EstadoTurno.desdeTexto('en_atencion'), EstadoTurno.enAtencion);
      expect(EstadoTurno.desdeTexto('completado'), EstadoTurno.completado);
      expect(EstadoTurno.desdeTexto('cancelado'), EstadoTurno.cancelado);
    });

    test(
      'desdeTexto usa esperando como valor por defecto ante texto desconocido',
      () {
        expect(EstadoTurno.desdeTexto('lo-que-sea'), EstadoTurno.esperando);
      },
    );

    test('aTexto es el inverso exacto de desdeTexto para cada valor', () {
      for (final estado in EstadoTurno.values) {
        expect(EstadoTurno.desdeTexto(estado.aTexto()), estado);
      }
    });
  });
}
