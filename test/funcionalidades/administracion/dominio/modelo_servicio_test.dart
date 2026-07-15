import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_servicio.dart';

void main() {
  group('ModeloServicio', () {
    test('desdeJson y aJson hacen roundtrip completo', () {
      final json = {
        'id': 'servicio-1',
        'barberia_id': 'barberia-1',
        'nombre': 'Corte Clásico',
        'descripcion': 'Corte tradicional a tijera o máquina',
        'duracion_min': 30,
        'precio': 50.0,
        'activo': true,
      };

      final servicio = ModeloServicio.desdeJson(json);

      expect(servicio.id, 'servicio-1');
      expect(servicio.barberiaId, 'barberia-1');
      expect(servicio.nombre, 'Corte Clásico');
      expect(servicio.descripcion, 'Corte tradicional a tijera o máquina');
      expect(servicio.duracionMin, 30);
      expect(servicio.precio, 50.0);
      expect(servicio.activo, true);
      expect(servicio.aJson(), json);
    });

    test('copyWith crea nueva instancia con modificaciones', () {
      final original = ModeloServicio(
        id: 'servicio-2',
        barberiaId: 'barberia-1',
        nombre: 'Barba',
        duracionMin: 20,
        precio: 30.0,
        activo: true,
      );

      final copia = original.copyWith(precio: 35.0, activo: false);

      expect(copia.id, 'servicio-2');
      expect(copia.precio, 35.0);
      expect(copia.activo, false);
    });
  });
}
