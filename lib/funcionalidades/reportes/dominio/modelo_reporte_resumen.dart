class ModeloReporteResumen {
  const ModeloReporteResumen({
    this.totalIngresos = 0,
    this.totalCitas = 0,
    this.totalClientesNuevos = 0,
    this.promedioTicketProp = 0,
    double? promedioTicket,
    double? ticketPromedio,
    this.totalDescuentos = 0,
    this.citasCompletadas = 0,
    this.citasCanceladas = 0,
  }) : promedioTicketVal = ticketPromedio ?? promedioTicket ?? promedioTicketProp;

  final double totalIngresos;
  final int totalCitas;
  final int totalClientesNuevos;
  final double promedioTicketProp;
  final double promedioTicketVal;
  final double totalDescuentos;
  final int citasCompletadas;
  final int citasCanceladas;

  double get promedioTicket => promedioTicketVal;
  double get ticketPromedio => promedioTicketVal;

  factory ModeloReporteResumen.desdeJson(Map<String, dynamic> json) {
    return ModeloReporteResumen(
      totalIngresos: (json['total_ingresos'] as num? ?? 0).toDouble(),
      totalCitas: json['total_citas'] as int? ?? 0,
      totalClientesNuevos: json['total_clientes_nuevos'] as int? ?? 0,
      promedioTicket: (json['promedio_ticket'] as num? ?? 0).toDouble(),
      totalDescuentos: (json['total_descuentos'] as num? ?? 0).toDouble(),
      citasCompletadas: json['citas_completadas'] as int? ?? 0,
      citasCanceladas: json['citas_canceladas'] as int? ?? 0,
    );
  }
}
