class ModeloReporteBarbero {
  const ModeloReporteBarbero({
    required this.barberoId,
    required this.barberoNombre,
    required this.cantidadCitas,
    required this.ingresosTotales,
  });

  final String barberoId;
  final String barberoNombre;
  final int cantidadCitas;
  final double ingresosTotales;

  factory ModeloReporteBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloReporteBarbero(
      barberoId: json['barbero_id'] as String,
      barberoNombre: json['barbero_nombre'] as String,
      cantidadCitas: json['cantidad_citas'] as int? ?? 0,
      ingresosTotales: (json['ingresos_totales'] as num? ?? 0).toDouble(),
    );
  }
}
