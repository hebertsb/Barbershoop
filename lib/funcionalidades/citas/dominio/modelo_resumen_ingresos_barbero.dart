class ModeloResumenIngresosBarbero {
  const ModeloResumenIngresosBarbero({
    required this.ingresosHoy,
    required this.ingresosSemana,
    required this.ingresosMes,
    required this.citasHoy,
  });

  final double ingresosHoy;
  final double ingresosSemana;
  final double ingresosMes;
  final int citasHoy;

  factory ModeloResumenIngresosBarbero.desdeJson(Map<String, dynamic> json) {
    return ModeloResumenIngresosBarbero(
      ingresosHoy: (json['ingresos_hoy'] as num).toDouble(),
      ingresosSemana: (json['ingresos_semana'] as num).toDouble(),
      ingresosMes: (json['ingresos_mes'] as num).toDouble(),
      citasHoy: json['citas_hoy'] as int,
    );
  }
}
