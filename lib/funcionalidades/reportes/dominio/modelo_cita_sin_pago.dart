class ModeloCitaSinPago {
  const ModeloCitaSinPago({
    required this.citaId,
    required this.clienteNombre,
    required this.precioCobrado,
    required this.montoPagado,
  });

  final String citaId;
  final String clienteNombre;
  final double precioCobrado;
  final double montoPagado;

  double get diferencia => precioCobrado - montoPagado;

  factory ModeloCitaSinPago.desdeJson(Map<String, dynamic> json) {
    return ModeloCitaSinPago(
      citaId: json['cita_id'] as String,
      clienteNombre: json['cliente_nombre'] as String,
      precioCobrado: (json['precio_cobrado'] as num).toDouble(),
      montoPagado: (json['monto_pagado'] as num).toDouble(),
    );
  }
}
