class ModeloReporteServicio {
  const ModeloReporteServicio({
    required this.servicioId,
    required this.nombre,
    required this.cantidadCitas,
    required this.totalGenerado,
  });

  final String servicioId;
  final String nombre;
  final int cantidadCitas;
  final double totalGenerado;

  /// Alias de [nombre].
  String get servicioNombre => nombre;

  /// Alias de [totalGenerado].
  double get ingresosTotales => totalGenerado;

  factory ModeloReporteServicio.desdeJson(Map<String, dynamic> json) {
    final tg = json['total_generado'] ?? json['ingresos_totales'];
    return ModeloReporteServicio(
      servicioId: json['servicio_id'] as String? ?? '',
      nombre: (json['nombre'] ?? json['servicio_nombre']) as String? ?? '',
      cantidadCitas: (json['cantidad_citas'] ?? json['citas_cantidad']) as int? ?? 0,
      totalGenerado: (tg as num? ?? 0).toDouble(),
    );
  }
}
