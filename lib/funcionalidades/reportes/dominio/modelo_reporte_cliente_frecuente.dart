class ModeloReporteClienteFrecuente {
  const ModeloReporteClienteFrecuente({
    required this.clienteId,
    required this.nombre,
    required this.totalVisitas,
    required this.montoTotalGastado,
  });

  final String clienteId;
  final String nombre;
  final int totalVisitas;
  final double montoTotalGastado;

  /// Alias de [nombre].
  String get clienteNombre => nombre;

  /// Alias de [totalVisitas].
  int get cantidadCitas => totalVisitas;

  /// Alias de [montoTotalGastado].
  double get montoTotal => montoTotalGastado;

  factory ModeloReporteClienteFrecuente.desdeJson(Map<String, dynamic> json) {
    final mt = json['monto_total_gastado'] ?? json['monto_total'];
    return ModeloReporteClienteFrecuente(
      clienteId: json['cliente_id'] as String? ?? '',
      nombre: (json['nombre'] ?? json['cliente_nombre']) as String? ?? 'Cliente',
      totalVisitas: (json['total_visitas'] ?? json['cantidad_citas']) as int? ?? 0,
      montoTotalGastado: (mt as num? ?? 0).toDouble(),
    );
  }
}
