import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/autenticacion/dominio/modelo_barberia_resumen.dart';

void main() {
  test('desdeJson mapea id y nombre', () {
    final barberia = ModeloBarberiaResumen.desdeJson({'id': 'b1', 'nombre': 'Barberia Central'});
    expect(barberia.id, 'b1');
    expect(barberia.nombre, 'Barberia Central');
  });
}
