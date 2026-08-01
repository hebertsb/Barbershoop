import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/elegir_programa_ranking_para_mostrar.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/enum_tipo_premio_ranking.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/modelo_programa_ranking_barberos.dart';

ModeloProgramaRankingBarberos _programa({
  required String id,
  required String estado,
  required DateTime fechaInicio,
  required DateTime fechaFin,
}) {
  return ModeloProgramaRankingBarberos(
    id: id,
    barberiaId: 'b1',
    sucursalId: 's1',
    titulo: id,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    pesoCitas: 100,
    pesoIngresos: 0,
    pesoClientes: 0,
    pesoPuntualidad: 0,
    pesoCalificacion: 0,
    tipoPremio: TipoPremioRanking.otro,
    descripcionPremio: 'x',
    estado: estado,
    premioEntregado: false,
  );
}

void main() {
  test('lista vacia devuelve null', () {
    expect(elegirProgramaRankingParaMostrar([]), isNull);
  });

  test('con un activo y varios cerrados, elige el activo', () {
    final activo = _programa(
      id: 'activo',
      estado: 'activo',
      fechaInicio: DateTime(2026, 8, 1),
      fechaFin: DateTime(2026, 8, 31),
    );
    final cerrado = _programa(
      id: 'cerrado',
      estado: 'cerrado',
      fechaInicio: DateTime(2026, 9, 1),
      fechaFin: DateTime(2026, 9, 30),
    );

    final elegido = elegirProgramaRankingParaMostrar([cerrado, activo]);

    expect(elegido?.id, 'activo');
  });

  test('con varios activos, elige el de fecha_inicio mas reciente', () {
    final viejo = _programa(
      id: 'viejo',
      estado: 'activo',
      fechaInicio: DateTime(2026, 6, 1),
      fechaFin: DateTime(2026, 6, 30),
    );
    final nuevo = _programa(
      id: 'nuevo',
      estado: 'activo',
      fechaInicio: DateTime(2026, 7, 1),
      fechaFin: DateTime(2026, 7, 31),
    );

    final elegido = elegirProgramaRankingParaMostrar([viejo, nuevo]);

    expect(elegido?.id, 'nuevo');
  });

  test('sin ningun activo, elige el cerrado de fecha_fin mas reciente', () {
    final viejo = _programa(
      id: 'viejo',
      estado: 'cerrado',
      fechaInicio: DateTime(2026, 5, 1),
      fechaFin: DateTime(2026, 5, 31),
    );
    final reciente = _programa(
      id: 'reciente',
      estado: 'cerrado',
      fechaInicio: DateTime(2026, 6, 1),
      fechaFin: DateTime(2026, 6, 30),
    );

    final elegido = elegirProgramaRankingParaMostrar([viejo, reciente]);

    expect(elegido?.id, 'reciente');
  });
}
