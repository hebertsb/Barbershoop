enum EstadoReporteInsumo {
  pendiente,
  aprobado,
  rechazado;

  static EstadoReporteInsumo desdeTexto(String texto) {
    return EstadoReporteInsumo.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => EstadoReporteInsumo.pendiente,
    );
  }
}
