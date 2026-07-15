import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_horario_barbero.dart';

void main() {
  group('ModeloHorarioBarbero', () {
    test('desdeJson y aJson hacen roundtrip completo y normalizan formato de hora', () {
      final json = {
        'id': 'horario-1',
        'barbero_id': 'barbero-1',
        'barberia_id': 'barberia-1',
        'dia_semana': 1,
        'hora_inicio': '09:00:00',
        'hora_fin': '18:00:00',
      };

      final horario = ModeloHorarioBarbero.desdeJson(json);

      expect(horario.id, 'horario-1');
      expect(horario.barberoId, 'barbero-1');
      expect(horario.barberiaId, 'barberia-1');
      expect(horario.diaSemana, 1);
      expect(horario.horaInicio, '09:00'); // Segundos removidos por la normalización
      expect(horario.horaFin, '18:00'); // Segundos removidos por la normalización

      // El roundtrip usa el JSON serializado con las horas normalizadas
      expect(horario.aJson(), {
        'id': 'horario-1',
        'barbero_id': 'barbero-1',
        'barberia_id': 'barberia-1',
        'dia_semana': 1,
        'hora_inicio': '09:00',
        'hora_fin': '18:00',
      });
    });

    test('copyWith crea nueva instancia con modificaciones', () {
      final original = ModeloHorarioBarbero(
        id: 'horario-2',
        barberoId: 'barbero-1',
        barberiaId: 'barberia-1',
        diaSemana: 2,
        horaInicio: '10:00',
        horaFin: '19:00',
      );

      final copia = original.copyWith(diaSemana: 3, horaInicio: '11:00');

      expect(copia.id, 'horario-2');
      expect(copia.diaSemana, 3);
      expect(copia.horaInicio, '11:00');
      expect(copia.horaFin, '19:00');
    });
  });
}
