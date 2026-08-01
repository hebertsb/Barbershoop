enum MetodoPago {
  efectivo,
  qrManual,
  pasarela;

  static MetodoPago desdeTexto(String texto) {
    switch (texto) {
      case 'efectivo':
        return MetodoPago.efectivo;
      case 'qr_manual':
        return MetodoPago.qrManual;
      case 'pasarela':
        return MetodoPago.pasarela;
      default:
        return MetodoPago.efectivo;
    }
  }

  String aTexto() {
    switch (this) {
      case MetodoPago.efectivo:
        return 'efectivo';
      case MetodoPago.qrManual:
        return 'qr_manual';
      case MetodoPago.pasarela:
        return 'pasarela';
    }
  }
}
