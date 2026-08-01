enum ModoPago {
  obligatorio,
  opcional,
  sena;

  static ModoPago desdeTexto(String texto) {
    switch (texto) {
      case 'obligatorio':
        return ModoPago.obligatorio;
      case 'opcional':
        return ModoPago.opcional;
      case 'sena':
        return ModoPago.sena;
      default:
        return ModoPago.opcional;
    }
  }

  String aTexto() {
    switch (this) {
      case ModoPago.obligatorio:
        return 'obligatorio';
      case ModoPago.opcional:
        return 'opcional';
      case ModoPago.sena:
        return 'sena';
    }
  }
}
