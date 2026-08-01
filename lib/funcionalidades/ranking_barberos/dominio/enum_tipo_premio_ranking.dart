enum TipoPremioRanking {
  dinero,
  diaLibre,
  reconocimiento,
  otro;

  static TipoPremioRanking desdeTexto(String texto) {
    switch (texto) {
      case 'dinero':
        return TipoPremioRanking.dinero;
      case 'dia_libre':
        return TipoPremioRanking.diaLibre;
      case 'reconocimiento':
        return TipoPremioRanking.reconocimiento;
      case 'otro':
        return TipoPremioRanking.otro;
      default:
        return TipoPremioRanking.otro;
    }
  }

  String aTexto() {
    switch (this) {
      case TipoPremioRanking.dinero:
        return 'dinero';
      case TipoPremioRanking.diaLibre:
        return 'dia_libre';
      case TipoPremioRanking.reconocimiento:
        return 'reconocimiento';
      case TipoPremioRanking.otro:
        return 'otro';
    }
  }

  String etiqueta() {
    switch (this) {
      case TipoPremioRanking.dinero:
        return 'Dinero';
      case TipoPremioRanking.diaLibre:
        return 'Día libre';
      case TipoPremioRanking.reconocimiento:
        return 'Reconocimiento';
      case TipoPremioRanking.otro:
        return 'Otro';
    }
  }
}
