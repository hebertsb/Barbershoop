class ModeloResumenIngresos {
  const ModeloResumenIngresos({
    required this.ingresosHoy,
    required this.ingresosMes,
    required this.ingresosAnio,
    required this.citasHoy,
    this.ingresosAyer,
    this.citasAyer,
  });

  final double ingresosHoy;
  final double ingresosMes;
  final double ingresosAnio;
  final int citasHoy;
  final double? ingresosAyer;
  final int? citasAyer;

  factory ModeloResumenIngresos.desdeJson(Map<String, dynamic> json) {
    return ModeloResumenIngresos(
      ingresosHoy: (json['ingresos_hoy'] as num).toDouble(),
      ingresosMes: (json['ingresos_mes'] as num).toDouble(),
      ingresosAnio: (json['ingresos_anio'] as num).toDouble(),
      citasHoy: json['citas_hoy'] as int,
      ingresosAyer: (json['ingresos_ayer'] as num?)?.toDouble(),
      citasAyer: json['citas_ayer'] as int?,
    );
  }
}
