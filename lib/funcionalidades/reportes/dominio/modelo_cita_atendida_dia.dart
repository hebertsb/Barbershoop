import '../../../../nucleo/utilidades/parsear_fecha_utc.dart';

class ModeloCitaAtendidaDia {
  const ModeloCitaAtendidaDia({
    required this.citaId,
    required this.hora,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.barberoNombre,
    required this.monto,
  });

  final String citaId;
  final DateTime hora;
  final String clienteNombre;
  final String servicioNombre;
  final String barberoNombre;
  final double monto;

  factory ModeloCitaAtendidaDia.desdeJson(Map<String, dynamic> json) {
    return ModeloCitaAtendidaDia(
      citaId: json['cita_id'] as String,
      hora: parsearFechaUtc(json['hora'] as String?),
      clienteNombre: json['cliente_nombre'] as String? ?? 'Cliente',
      servicioNombre: json['servicio_nombre'] as String? ?? '',
      barberoNombre: json['barbero_nombre'] as String? ?? 'Barbero',
      monto: (json['monto'] as num? ?? 0).toDouble(),
    );
  }
}