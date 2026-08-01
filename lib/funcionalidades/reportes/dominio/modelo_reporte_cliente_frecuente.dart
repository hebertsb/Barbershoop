class ModeloReporteClienteFrecuente {
  const ModeloReporteClienteFrecuente({
    required this.clienteId,
    required this.clienteNombre,
    required this.cantidadCitas,
    required this.montoTotal,
  });

  final String clienteId;
  final String clienteNombre;
  final int cantidadCitas;
  final double montoTotal;

  factory ModeloReporteClienteFrecuente.desdeJson(Map<String, dynamic> json) {
    return ModeloReporteClienteFrecuente(
      clienteId: json['cliente_id'] as String,
      clienteNombre: json['cliente_nombre'] as String,
      cantidadCitas: json['cantidad_citas'] as int,
      montoTotal: (json['monto_total'] as num).toDouble(),
    );
  }
}
