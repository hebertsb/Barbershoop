import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/modelo_horario_disponible.dart';

void main() {
  test('desdeJson mapea barbero_id y hora_inicio', () {
    final horario = ModeloHorarioDisponible.desdeJson({
      'barbero_id': 'barbero-1',
      'hora_inicio': '2026-07-20T13:00:00.000Z',
    });

    expect(horario.barberoId, 'barbero-1');
    expect(horario.horaInicio, DateTime.parse('2026-07-20T13:00:00.000Z'));
  });
}
