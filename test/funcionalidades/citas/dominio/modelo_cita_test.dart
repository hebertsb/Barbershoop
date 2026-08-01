import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/citas/dominio/modelo_cita.dart';
import 'package:barber_app/funcionalidades/citas/dominio/enum_estado_cita.dart';

void main() {
  group('ModeloCita', () {
    test('desdeJson y aJson hacen roundtrip completo', () {
      final json = {
        'id': 'cita-1',
        'barberia_id': 'barberia-1',
        'sucursal_id': 'sucursal-1',
        'barbero_id': 'barbero-1',
        'cliente_id': 'cliente-1',
        'cliente_walkin_id': null,
        'servicio_id': 'servicio-1',
        'fecha_hora': '2026-07-17T15:00:00.000Z',
        'duracion_min': 30,
        'estado': 'confirmada',
        'precio_cobrado': 50.0,
      };

      final cita = ModeloCita.desdeJson(json);

      expect(cita.id, 'cita-1');
      expect(cita.barberiaId, 'barberia-1');
      expect(cita.sucursalId, 'sucursal-1');
      expect(cita.barberoId, 'barbero-1');
      expect(cita.clienteId, 'cliente-1');
      expect(cita.clienteWalkinId, isNull);
      expect(cita.servicioId, 'servicio-1');
      expect(cita.fechaHora, DateTime.parse('2026-07-17T15:00:00.000Z'));
      expect(cita.duracionMin, 30);
      expect(cita.estado, EstadoCita.confirmada);
      expect(cita.precioCobrado, 50.0);
      expect(cita.aJson(), json);
    });

    test('desdeJson admite cliente_walkin_id en vez de cliente_id', () {
      final cita = ModeloCita.desdeJson({
        'id': 'cita-2',
        'barberia_id': 'barberia-1',
        'sucursal_id': 'sucursal-1',
        'barbero_id': 'barbero-1',
        'cliente_id': null,
        'cliente_walkin_id': 'walkin-1',
        'servicio_id': 'servicio-1',
        'fecha_hora': '2026-07-17T16:00:00.000Z',
        'duracion_min': 45,
        'estado': 'completada',
        'precio_cobrado': null,
      });

      expect(cita.clienteId, isNull);
      expect(cita.clienteWalkinId, 'walkin-1');
      expect(cita.precioCobrado, isNull);
    });

    test('copyWith actualiza estado y precioCobrado sin tocar el resto', () {
      final original = ModeloCita(
        id: 'cita-3',
        barberiaId: 'barberia-1',
        sucursalId: 'sucursal-1',
        barberoId: 'barbero-1',
        clienteId: 'cliente-1',
        servicioId: 'servicio-1',
        fechaHora: DateTime(2026, 7, 17, 12),
        duracionMin: 30,
        estado: EstadoCita.pendiente,
      );

      final actualizado = original.copyWith(
        estado: EstadoCita.completada,
        precioCobrado: 45.0,
      );

      expect(actualizado.estado, EstadoCita.completada);
      expect(actualizado.precioCobrado, 45.0);
      expect(actualizado.id, original.id);
      expect(actualizado.clienteId, original.clienteId);
    });

    test('puedeReprogramarse es true si faltan más minutos que el mínimo', () {
      final cita = ModeloCita(
        id: 'cita-4',
        barberiaId: 'barberia-1',
        sucursalId: 'sucursal-1',
        barberoId: 'barbero-1',
        clienteId: 'cliente-1',
        servicioId: 'servicio-1',
        fechaHora: DateTime.now().add(const Duration(hours: 2)),
        duracionMin: 30,
        estado: EstadoCita.pendiente,
      );

      expect(cita.puedeReprogramarse(60), isTrue);
    });

    test(
      'puedeReprogramarse es false si faltan menos minutos que el mínimo',
      () {
        final cita = ModeloCita(
          id: 'cita-5',
          barberiaId: 'barberia-1',
          sucursalId: 'sucursal-1',
          barberoId: 'barbero-1',
          clienteId: 'cliente-1',
          servicioId: 'servicio-1',
          fechaHora: DateTime.now().add(const Duration(minutes: 10)),
          duracionMin: 30,
          estado: EstadoCita.pendiente,
        );

        expect(cita.puedeReprogramarse(60), isFalse);
      },
    );
  });
}
