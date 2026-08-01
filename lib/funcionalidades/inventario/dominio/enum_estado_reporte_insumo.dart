enum EstadoReporteInsumo {
  pendiente,
  atendido,
  rechazado;

  static EstadoReporteInsumo desdeTexto(String texto) {
    switch (texto) {
      case 'pendiente':
        return EstadoReporteInsumo.pendiente;
      case 'atendido':
        return EstadoReporteInsumo.atendido;
      case 'rechazado':
        return EstadoReporteInsumo.rechazado;
      default:
        return EstadoReporteInsumo.pendiente;
    }
  }

  String aTexto() {
    switch (this) {
      case EstadoReporteInsumo.pendiente:
        return 'pendiente';
      case EstadoReporteInsumo.atendido:
        return 'atendido';
      case EstadoReporteInsumo.rechazado:
        return 'rechazado';
    }
  }
}
