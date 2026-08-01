import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/modelo_turno.dart';
import 'package:barber_app/funcionalidades/turnos/dominio/enum_estado_turno.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/enum_metodo_pago.dart';

void main() {
  group('ModeloTurno', () {
    test('desdeJson y aJson hacen roundtrip completo', () {
      final json = {
        'id': 'turno-1',
        'barberia_id': 'barberia-1',
        'sucursal_id': 'sucursal-1',
        'numero': 3,
        'cliente_id': null,
        'cliente_walkin_id': 'walkin-1',
        'servicio_id': 'servicio-1',
        'barbero_id': null,
        'estado': 'esperando',
        'cita_id': null,
        'hora_llegada': '2026-07-17T10:00:00.000Z',
        'hora_atencion': null,
        'hora_completado': null,
        'monto_precobrado': null,
        'metodo_precobrado': null,
      };

      final turno = ModeloTurno.desdeJson(json);

      expect(turno.id, 'turno-1');
      expect(turno.barberiaId, 'barberia-1');
      expect(turno.sucursalId, 'sucursal-1');
      expect(turno.numero, 3);
      expect(turno.clienteId, isNull);
      expect(turno.clienteWalkinId, 'walkin-1');
      expect(turno.servicioId, 'servicio-1');
      expect(turno.barberoId, isNull);
      expect(turno.estado, EstadoTurno.esperando);
      expect(turno.citaId, isNull);
      expect(turno.horaLlegada, DateTime.parse('2026-07-17T10:00:00.000Z'));
      expect(turno.horaAtencion, isNull);
      expect(turno.horaCompletado, isNull);
      expect(turno.montoPrecobrado, isNull);
      expect(turno.metodoPrecobrado, isNull);
      expect(turno.aJson(), json);
    });

    test('desdeJson y aJson hacen roundtrip con cobro anticipado', () {
      final json = {
        'id': 'turno-9',
        'barberia_id': 'barberia-1',
        'sucursal_id': 'sucursal-1',
        'numero': 5,
        'cliente_id': null,
        'cliente_walkin_id': 'walkin-1',
        'servicio_id': 'servicio-1',
        'barbero_id': null,
        'estado': 'esperando',
        'cita_id': null,
        'hora_llegada': '2026-07-17T10:00:00.000Z',
        'hora_atencion': null,
        'hora_completado': null,
        'monto_precobrado': 45.5,
        'metodo_precobrado': 'qr_manual',
      };

      final turno = ModeloTurno.desdeJson(json);

      expect(turno.montoPrecobrado, 45.5);
      expect(turno.metodoPrecobrado, MetodoPago.qrManual);
      expect(turno.aJson(), json);
    });

    test('copyWith actualiza estado y barbero sin tocar el resto', () {
      final original = ModeloTurno.desdeJson({
        'id': 'turno-2',
        'barberia_id': 'barberia-1',
        'sucursal_id': 'sucursal-1',
        'numero': 1,
        'cliente_id': 'cliente-1',
        'cliente_walkin_id': null,
        'servicio_id': 'servicio-1',
        'barbero_id': null,
        'estado': 'esperando',
        'cita_id': null,
        'hora_llegada': '2026-07-17T09:00:00.000Z',
        'hora_atencion': null,
        'hora_completado': null,
        'monto_precobrado': null,
        'metodo_precobrado': null,
      });

      final actualizado = original.copyWith(
        estado: EstadoTurno.enAtencion,
        barberoId: 'barbero-1',
      );

      expect(actualizado.estado, EstadoTurno.enAtencion);
      expect(actualizado.barberoId, 'barbero-1');
      expect(actualizado.numero, original.numero);
      expect(actualizado.clienteId, original.clienteId);
    });
  });
}
