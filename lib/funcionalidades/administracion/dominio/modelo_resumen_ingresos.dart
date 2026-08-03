class ModeloResumenIngresos {
  const ModeloResumenIngresos({
    this.totalIngresos = 0,
    this.totalCitas = 0,
    this.promedioPorCita = 0,
    this.ingresosHoy = 0,
    this.ingresosAyer = 0,
    this.citasHoy = 0,
    this.citasAyer = 0,
  });

  final double totalIngresos;
  final int totalCitas;
  final double promedioPorCita;
  final double ingresosHoy;
  final double ingresosAyer;
  final int citasHoy;
  final int citasAyer;

  factory ModeloResumenIngresos.desdeJson(Map<String, dynamic> json) {
    return ModeloResumenIngresos(
      totalIngresos: (json['total_ingresos'] as num? ?? 0).toDouble(),
      totalCitas: json['total_citas'] as int? ?? 0,
      promedioPorCita: (json['promedio_por_cita'] as num? ?? 0).toDouble(),
      ingresosHoy: (json['ingresos_hoy'] as num? ?? 0).toDouble(),
      ingresosAyer: (json['ingresos_ayer'] as num? ?? 0).toDouble(),
      citasHoy: json['citas_hoy'] as int? ?? 0,
      citasAyer: json['citas_ayer'] as int? ?? 0,
    );
  }
}
