enum EstadoCita {
  pendiente,
  confirmada,
  enProceso,
  completada,
  cancelada,
  noAsistio;

  /// Texto legible en español del estado.
  String aTexto() {
    switch (this) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.enProceso:
        return 'En Proceso';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.noAsistio:
        return 'No asistió';
    }
  }

  static EstadoCita desdeTexto(String texto) {
    return EstadoCita.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => EstadoCita.pendiente,
    );
  }
}
