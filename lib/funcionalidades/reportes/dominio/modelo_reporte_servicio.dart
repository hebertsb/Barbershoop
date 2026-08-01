class ModeloReporteServicio {
  const ModeloReporteServicio({
    required this.servicioId,
    required this.servicioNombre,
    required this.cantidadCitas,
    required this.ingresosTotales,
  });

  final String servicioId;
  final String servicioNombre;
  final int cantidadCitas;
  final double ingresosTotales;

  factory ModeloReporteServicio.desdeJson(Map<String, dynamic> json) {
    return ModeloReporteServicio(
      servicioId: json['servicio_id'] as String,
      servicioNombre: json['servicio_nombre'] as String,
      cantidadCitas: json['cantidad_citas'] as int,
      ingresosTotales: (json['ingresos_totales'] as num).toDouble(),
    );
  }
}
