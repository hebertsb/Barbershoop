import 'package:flutter_test/flutter_test.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/enum_estado_pago.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/modelo_pago.dart';
import 'package:barber_app/funcionalidades/pagos/dominio/enum_metodo_pago.dart';

void main() {
  test('desdeJson mapea los campos planos', () {
    final pago = ModeloPago.desdeJson({
      'id': 'p1',
      'barberia_id': 'b1',
      'cita_id': 'c1',
      'monto': 50.0,
      'metodo': 'qr_manual',
      'estado': 'por_verificar',
      'url_comprobante': 'https://ejemplo.com/foto.jpg',
      'verificado_por': null,
      'fecha': '2026-07-19T10:00:00.000Z',
    });

    expect(pago.id, 'p1');
    expect(pago.citaId, 'c1');
    expect(pago.monto, 50.0);
    expect(pago.metodo, MetodoPago.qrManual);
    expect(pago.estado, EstadoPago.porVerificar);
    expect(pago.urlComprobante, 'https://ejemplo.com/foto.jpg');
    expect(pago.nombreCliente, isNull);
  });

  test('desdeJson mapea el embed de citas/perfiles cuando esta presente', () {
    final pago = ModeloPago.desdeJson({
      'id': 'p1',
      'barberia_id': 'b1',
      'cita_id': 'c1',
      'monto': 50.0,
      'metodo': 'qr_manual',
      'estado': 'por_verificar',
      'url_comprobante': 'https://ejemplo.com/foto.jpg',
      'verificado_por': null,
      'fecha': '2026-07-19T10:00:00.000Z',
      'citas': {
        'fecha_hora': '2026-07-20T13:00:00.000Z',
        'perfiles': {'nombre': 'Hebert Suárez'},
      },
    });

    expect(pago.nombreCliente, 'Hebert Suárez');
    expect(pago.fechaHoraCita, DateTime.parse('2026-07-20T13:00:00.000Z'));
  });
}
