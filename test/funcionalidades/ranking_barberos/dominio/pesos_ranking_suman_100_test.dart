import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/ranking_barberos/dominio/pesos_ranking_suman_100.dart';

void main() {
  test('pesos que suman exactamente 100 son validos', () {
    expect(
      pesosRankingSuman100(
        pesoCitas: 30,
        pesoIngresos: 30,
        pesoClientes: 20,
        pesoPuntualidad: 10,
        pesoCalificacion: 10,
      ),
      isTrue,
    );
  });

  test('pesos que no suman 100 son invalidos', () {
    expect(
      pesosRankingSuman100(
        pesoCitas: 30,
        pesoIngresos: 30,
        pesoClientes: 20,
        pesoPuntualidad: 5,
        pesoCalificacion: 10,
      ),
      isFalse,
    );
  });

  test('un solo factor al 100% y el resto en 0 es valido', () {
    expect(
      pesosRankingSuman100(
        pesoCitas: 100,
        pesoIngresos: 0,
        pesoClientes: 0,
        pesoPuntualidad: 0,
        pesoCalificacion: 0,
      ),
      isTrue,
    );
  });

  test('5 pesos que suman 100 repartidos entre todos son validos', () {
    expect(
      pesosRankingSuman100(
        pesoCitas: 20,
        pesoIngresos: 20,
        pesoClientes: 20,
        pesoPuntualidad: 20,
        pesoCalificacion: 20,
      ),
      isTrue,
    );
  });
}
