class ModeloPuntoTendencia {
  const ModeloPuntoTendencia({required this.fecha, required this.monto});

  final DateTime fecha;
  final double monto;

  factory ModeloPuntoTendencia.desdeJson(Map<String, dynamic> json) {
    return ModeloPuntoTendencia(
      fecha: DateTime.parse(json['fecha'] as String),
      monto: (json['monto'] as num).toDouble(),
    );
  }
}
