enum EstadoTurno {
  pendiente,
  enProceso,
  completado,
  cancelado,

  /// Alias de [pendiente]: el cliente llegó y está esperando ser atendido.
  esperando,

  /// Alias de [enProceso]: el barbero está atendiendo al cliente ahora.
  enAtencion;

  String aTexto() => name;

  static EstadoTurno desdeTexto(String texto) {
    return EstadoTurno.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => EstadoTurno.pendiente,
    );
  }
}
