import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/enum_tipo_premio_ranking.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/modelo_programa_ranking_barberos.dart';

void main() {
  group('ModeloProgramaRankingBarberos', () {
    test('desdeJson parsea todos los campos, incluido el ganador embebido', () {
      final json = {
        'id': 'p1',
        'barberia_id': 'b1',
        'sucursal_id': 's1',
        'titulo': 'Ranking de Julio',
        'fecha_inicio': '2026-07-01',
        'fecha_fin': '2026-07-31',
        'peso_citas': 30,
        'peso_ingresos': 30,
        'peso_clientes': 20,
        'peso_puntualidad': 10,
        'peso_calificacion': 10,
        'tipo_premio': 'dinero',
        'descripcion_premio': 'Bs 200',
        'estado': 'cerrado',
        'barbero_ganador_id': 'bg1',
        'premio_entregado': false,
        'cerrado_en': '2026-08-01T10:00:00Z',
        'barbero_ganador': {
          'id': 'bg1',
          'perfiles': {'nombre': 'Juan Carlos'},
        },
      };

      final modelo = ModeloProgramaRankingBarberos.desdeJson(json);

      expect(modelo.id, 'p1');
      expect(modelo.titulo, 'Ranking de Julio');
      expect(modelo.fechaInicio, DateTime(2026, 7, 1));
      expect(modelo.fechaFin, DateTime(2026, 7, 31));
      expect(modelo.pesoCitas, 30);
      expect(modelo.tipoPremio, TipoPremioRanking.dinero);
      expect(modelo.estado, 'cerrado');
      expect(modelo.premioEntregado, false);
      expect(modelo.nombreGanador, 'Juan Carlos');
    });

    test('desdeJson sin ganador embebido deja nombreGanador null', () {
      final json = {
        'id': 'p1',
        'barberia_id': 'b1',
        'sucursal_id': 's1',
        'titulo': 'Ranking de Agosto',
        'fecha_inicio': '2026-08-01',
        'fecha_fin': '2026-08-31',
        'peso_citas': 100,
        'peso_ingresos': 0,
        'peso_clientes': 0,
        'peso_puntualidad': 0,
        'peso_calificacion': 0,
        'tipo_premio': 'sorpresa',
        'descripcion_premio': 'Se revela el día de la premiación',
        'estado': 'activo',
        'barbero_ganador_id': null,
        'premio_entregado': false,
        'cerrado_en': null,
      };

      final modelo = ModeloProgramaRankingBarberos.desdeJson(json);

      expect(modelo.nombreGanador, isNull);
      expect(modelo.barberoGanadorId, isNull);
    });

    test('aJson serializa fechas como yyyy-MM-dd', () {
      final modelo = ModeloProgramaRankingBarberos(
        id: '',
        barberiaId: '',
        sucursalId: 's1',
        titulo: 'Test',
        fechaInicio: DateTime(2026, 7, 1),
        fechaFin: DateTime(2026, 7, 31),
        pesoCitas: 20,
        pesoIngresos: 20,
        pesoClientes: 20,
        pesoPuntualidad: 20,
        pesoCalificacion: 20,
        tipoPremio: TipoPremioRanking.otro,
        descripcionPremio: 'Algo',
        estado: 'activo',
        premioEntregado: false,
      );

      final json = modelo.aJson();

      expect(json['fecha_inicio'], '2026-07-01');
      expect(json['fecha_fin'], '2026-07-31');
      expect(json['tipo_premio'], 'otro');
      expect(json.containsKey('barbero_ganador'), isFalse);
    });
  });
}
