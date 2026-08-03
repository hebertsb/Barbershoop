class ModeloCitaSinPago {
  const ModeloCitaSinPago({
    required this.citaId,
    required this.fechaHora,
    required this.clienteNombre,
    required this.barberoNombre,
    required this.precioCobrado,
    required this.montoPagado,
    required this.diferencia,
  });

  final String citaId;
  final DateTime fechaHora;
  final String clienteNombre;
  final String barberoNombre;
  final double precioCobrado;
  final double montoPagado;
  final double diferencia;

  factory ModeloCitaSinPago.desdeJson(Map<String, dynamic> json) {
    return ModeloCitaSinPago(
      citaId: json['cita_id'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String).toLocal(),
      clienteNombre: json['cliente_nombre'] as String? ?? 'Cliente',
      barberoNombre: json['barbero_nombre'] as String? ?? 'Barbero',
      precioCobrado: (json['precio_cobrado'] as num? ?? 0).toDouble(),
      montoPagado: (json['monto_pagado'] as num? ?? 0).toDouble(),
      diferencia: (json['diferencia'] as num? ?? 0).toDouble(),
    );
  }
}