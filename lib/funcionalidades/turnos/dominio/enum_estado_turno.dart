enum EstadoTurno {
  esperando,
  enAtencion,
  completado,
  cancelado;

  static EstadoTurno desdeTexto(String texto) {
    switch (texto) {
      case 'esperando':
        return EstadoTurno.esperando;
      case 'en_atencion':
        return EstadoTurno.enAtencion;
      case 'completado':
        return EstadoTurno.completado;
      case 'cancelado':
        return EstadoTurno.cancelado;
      default:
        return EstadoTurno.esperando;
    }
  }

  String aTexto() {
    switch (this) {
      case EstadoTurno.esperando:
        return 'esperando';
      case EstadoTurno.enAtencion:
        return 'en_atencion';
      case EstadoTurno.completado:
        return 'completado';
      case EstadoTurno.cancelado:
        return 'cancelado';
    }
  }
}
