import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/modelo_insignia_ranking_barbero.dart';

void main() {
  test('desdeJson parsea la insignia con el titulo del programa embebido', () {
    final json = {
      'id': 'i1',
      'programa_id': 'p1',
      'barbero_id': 'b1',
      'puesto': 1,
      'otorgada_en': '2026-08-01T10:00:00Z',
      'programas_ranking_barberos': {'titulo': 'Ranking de Julio'},
    };

    final insignia = ModeloInsigniaRankingBarbero.desdeJson(json);

    expect(insignia.id, 'i1');
    expect(insignia.puesto, 1);
    expect(insignia.tituloPrograma, 'Ranking de Julio');
    expect(insignia.otorgadaEn, DateTime.parse('2026-08-01T10:00:00Z'));
  });

  test('desdeJson sin titulo embebido usa cadena vacia', () {
    final json = {
      'id': 'i1',
      'programa_id': 'p1',
      'barbero_id': 'b1',
      'puesto': 2,
      'otorgada_en': '2026-08-01T10:00:00Z',
    };

    final insignia = ModeloInsigniaRankingBarbero.desdeJson(json);

    expect(insignia.tituloPrograma, '');
  });
}
