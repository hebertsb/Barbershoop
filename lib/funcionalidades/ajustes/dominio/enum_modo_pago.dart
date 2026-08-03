enum ModoPago {
  obligatorio,
  opcional,
  sena;

  String aTexto() => name;

  static ModoPago desdeTexto(String texto) {
    return ModoPago.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => ModoPago.opcional,
    );
  }
}
