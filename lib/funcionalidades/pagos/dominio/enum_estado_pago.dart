enum EstadoPago {
  pendiente,
  porVerificar,
  confirmado,
  rechazado;

  static EstadoPago desdeTexto(String texto) {
    return EstadoPago.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => EstadoPago.pendiente,
    );
  }
}
