class ModeloReporteResumen {
  const ModeloReporteResumen({
    required this.totalIngresos,
    required this.totalDescuentos,
    required this.citasCompletadas,
    required this.citasCanceladas,
    required this.ticketPromedio,
  });

  final double totalIngresos;
  final double totalDescuentos;
  final int citasCompletadas;
  final int citasCanceladas;
  final double ticketPromedio;

  factory ModeloReporteResumen.desdeJson(Map<String, dynamic> json) {
    return ModeloReporteResumen(
      totalIngresos: (json['total_ingresos'] as num).toDouble(),
      totalDescuentos: (json['total_descuentos'] as num).toDouble(),
      citasCompletadas: json['citas_completadas'] as int,
      citasCanceladas: json['citas_canceladas'] as int,
      ticketPromedio: (json['ticket_promedio'] as num).toDouble(),
    );
  }
}
