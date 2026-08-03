class ModeloResumenIngresosBarbero {
  const ModeloResumenIngresosBarbero({
    required this.barberoId,
    required this.barberoNombre,
    this.totalIngresos = 0,
    this.totalCitas = 0,
    this.ingresosHoy = 0,
    this.ingresosSemana = 0,
    this.ingresosMes = 0,
  });

  final String barberoId;
  final String barberoNombre;
  final double totalIngresos;
  final int totalCitas;

  final double ingresosHoy;
  final double ingresosSemana;
  final double ingresosMes;

  factory ModeloResumenIngresosBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloResumenIngresosBarbero(
      barberoId: json['barbero_id'] as String? ?? '',
      barberoNombre: json['barbero_nombre'] as String? ?? 'Barbero',
      totalIngresos: (json['total_ingresos'] as num? ?? 0).toDouble(),
      totalCitas: json['total_citas'] as int? ?? 0,
      ingresosHoy: (json['ingresos_hoy'] as num? ?? json['hoy'] as num? ?? 0).toDouble(),
      ingresosSemana: (json['ingresos_semana'] as num? ?? json['semana'] as num? ?? 0).toDouble(),
      ingresosMes: (json['ingresos_mes'] as num? ?? json['mes'] as num? ?? 0).toDouble(),
    );
  }
}
