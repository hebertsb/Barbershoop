enum ModoCobroCaja {
  alFinal,
  alLlegar;

  static ModoCobroCaja desdeTexto(String texto) {
    switch (texto) {
      case 'al_final':
        return ModoCobroCaja.alFinal;
      case 'al_llegar':
        return ModoCobroCaja.alLlegar;
      default:
        return ModoCobroCaja.alFinal;
    }
  }

  String aTexto() {
    switch (this) {
      case ModoCobroCaja.alFinal:
        return 'al_final';
      case ModoCobroCaja.alLlegar:
        return 'al_llegar';
    }
  }
}
