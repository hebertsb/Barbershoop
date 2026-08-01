enum EstadoCita {
  pendiente,
  confirmada,
  completada,
  cancelada,
  noAsistio;

  static EstadoCita desdeTexto(String texto) {
    switch (texto) {
      case 'pendiente':
        return EstadoCita.pendiente;
      case 'confirmada':
        return EstadoCita.confirmada;
      case 'completada':
        return EstadoCita.completada;
      case 'cancelada':
        return EstadoCita.cancelada;
      case 'no_asistio':
        return EstadoCita.noAsistio;
      default:
        return EstadoCita.pendiente;
    }
  }

  String aTexto() {
    switch (this) {
      case EstadoCita.pendiente:
        return 'pendiente';
      case EstadoCita.confirmada:
        return 'confirmada';
      case EstadoCita.completada:
        return 'completada';
      case EstadoCita.cancelada:
        return 'cancelada';
      case EstadoCita.noAsistio:
        return 'no_asistio';
    }
  }
}
