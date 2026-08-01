import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_servicio.dart';
import 'package:barber_app/funcionalidades/reservas/dominio/calculo_precio_combo.dart';

ModeloServicio _servicio(String id, double precio) {
  return ModeloServicio(
    id: id,
    barberiaId: 'b1',
    nombre: 'Servicio $id',
    duracionMin: 30,
    precio: precio,
    activo: true,
  );
}

void main() {
  group('precioBaseCombo', () {
    test('suma el precio de todos los servicios de la lista de ids', () {
      final servicios = [
        _servicio('s1', 50),
        _servicio('s2', 30),
        _servicio('s3', 20),
      ];
      final total = precioBaseCombo(['s1', 's2'], servicios);
      expect(total, 80);
    });

    test(
      'ids no encontrados en la lista de servicios no suman (contribuyen 0)',
      () {
        final servicios = [_servicio('s1', 50)];
        final total = precioBaseCombo(['s1', 's-inexistente'], servicios);
        expect(total, 50);
      },
    );

    test('lista de ids vacía da 0', () {
      final servicios = [_servicio('s1', 50)];
      final total = precioBaseCombo([], servicios);
      expect(total, 0);
    });
  });
}
