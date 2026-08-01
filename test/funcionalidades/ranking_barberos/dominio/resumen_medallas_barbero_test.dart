import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/modelo_insignia_ranking_barbero.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/resumen_medallas_barbero.dart';

ModeloInsigniaRankingBarbero _insignia(String barberoId, int puesto) {
  return ModeloInsigniaRankingBarbero(
    id: '$barberoId-$puesto-${DateTime.now().microsecondsSinceEpoch}',
    programaId: 'p',
    barberoId: barberoId,
    puesto: puesto,
    otorgadaEn: DateTime(2026, 7, 1),
    tituloPrograma: 'Programa',
  );
}

void main() {
  group('resumenMedallasDesde', () {
    test('cuenta oro/plata/bronce correctamente', () {
      final r = resumenMedallasDesde([
        _insignia('b1', 1),
        _insignia('b1', 1),
        _insignia('b1', 2),
        _insignia('b1', 3),
        _insignia('b1', 3),
        _insignia('b1', 3),
      ]);

      expect(r.oro, 2);
      expect(r.plata, 1);
      expect(r.bronce, 3);
      expect(r.total, 6);
    });

    test('lista vacia da todo en cero', () {
      final r = resumenMedallasDesde([]);
      expect(r.total, 0);
    });
  });

  group('agruparMedallasPorBarbero', () {
    test('agrupa insignias de varios barberos en un mapa', () {
      final mapa = agruparMedallasPorBarbero([
        _insignia('b1', 1),
        _insignia('b2', 2),
        _insignia('b1', 3),
      ]);

      expect(mapa['b1']!.oro, 1);
      expect(mapa['b1']!.bronce, 1);
      expect(mapa['b2']!.plata, 1);
      expect(mapa.containsKey('b3'), isFalse);
    });
  });
}
