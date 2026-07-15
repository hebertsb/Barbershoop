import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/administracion/dominio/modelo_sucursal.dart';

void main() {
  group('ModeloSucursal', () {
    test('desdeJson normaliza el horario (quita segundos) y aJson refleja eso', () {
      final json = {
        'id': 'sucursal-1',
        'barberia_id': 'barberia-1',
        'nombre': 'Sucursal Norte',
        'direccion': 'Calle Norte 123',
        'telefono': '71234567',
        'horario_apertura': '09:00:00',
        'horario_cierre': '20:00:00',
        'activo': true,
      };

      final sucursal = ModeloSucursal.desdeJson(json);

      expect(sucursal.id, 'sucursal-1');
      expect(sucursal.barberiaId, 'barberia-1');
      expect(sucursal.nombre, 'Sucursal Norte');
      expect(sucursal.direccion, 'Calle Norte 123');
      expect(sucursal.telefono, '71234567');
      expect(sucursal.horarioApertura, '09:00'); // Segundos removidos por la normalización
      expect(sucursal.horarioCierre, '20:00'); // Segundos removidos por la normalización
      expect(sucursal.activo, true);
      expect(sucursal.aJson(), {
        ...json,
        'horario_apertura': '09:00',
        'horario_cierre': '20:00',
      });
    });

    test('copyWith crea nueva instancia con modificaciones', () {
      final original = ModeloSucursal(
        id: 'sucursal-2',
        barberiaId: 'barberia-1',
        nombre: 'Sucursal Sur',
        activo: true,
      );

      final copia = original.copyWith(nombre: 'Sucursal Sur Modificada', activo: false);

      expect(copia.id, 'sucursal-2');
      expect(copia.nombre, 'Sucursal Sur Modificada');
      expect(copia.activo, false);
    });
  });
}
