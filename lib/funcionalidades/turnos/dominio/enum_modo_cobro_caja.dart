enum ModoCobroCaja {
  alInicio,
  alLlegar,
  alFinal;

  static ModoCobroCaja desdeTexto(String texto) {
    return ModoCobroCaja.values.firstWhere(
      (v) => v.name == texto,
      orElse: () => ModoCobroCaja.alFinal,
    );
  }
}
