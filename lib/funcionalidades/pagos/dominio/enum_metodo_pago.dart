enum MetodoPago {
  efectivo,
  qr,
  qrManual,
  tarjeta,
  transferencia;

  String aTexto() => name;

  static MetodoPago desdeTexto(String texto) {
    return MetodoPago.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => MetodoPago.efectivo,
    );
  }
}
