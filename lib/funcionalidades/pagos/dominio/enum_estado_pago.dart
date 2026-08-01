enum EstadoPago {
  pendiente,
  porVerificar,
  confirmado,
  rechazado;

  static EstadoPago desdeTexto(String texto) {
    switch (texto) {
      case 'pendiente':
        return EstadoPago.pendiente;
      case 'por_verificar':
        return EstadoPago.porVerificar;
      case 'confirmado':
        return EstadoPago.confirmado;
      case 'rechazado':
        return EstadoPago.rechazado;
      default:
        return EstadoPago.pendiente;
    }
  }

  String aTexto() {
    switch (this) {
      case EstadoPago.pendiente:
        return 'pendiente';
      case EstadoPago.porVerificar:
        return 'por_verificar';
      case EstadoPago.confirmado:
        return 'confirmado';
      case EstadoPago.rechazado:
        return 'rechazado';
    }
  }
}
