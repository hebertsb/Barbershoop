class ModeloCitaAtendidaDia {
  const ModeloCitaAtendidaDia({
    required this.hora,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.barberoNombre,
    required this.monto,
  });

  final DateTime hora;
  final String clienteNombre;
  final String servicioNombre;
  final String barberoNombre;
  final double monto;

  factory ModeloCitaAtendidaDia.desdeJson(Map<String, dynamic> json) {
    return ModeloCitaAtendidaDia(
      hora: DateTime.parse(json['hora'] as String),
      clienteNombre: json['cliente_nombre'] as String,
      servicioNombre: json['servicio_nombre'] as String,
      barberoNombre: json['barbero_nombre'] as String,
      monto: (json['monto'] as num).toDouble(),
    );
  }
}
