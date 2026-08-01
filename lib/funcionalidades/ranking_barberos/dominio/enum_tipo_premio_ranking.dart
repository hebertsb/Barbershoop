enum TipoPremioRanking {
  bono,
  diaLibre,
  reconocimiento,
  otro;

  static TipoPremioRanking desdeTexto(String texto) {
    switch (texto) {
      case 'bono':
        return TipoPremioRanking.bono;
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
      case TipoPremioRanking.bono:
        return 'bono';
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
      case TipoPremioRanking.bono:
        return 'Bono';
      case TipoPremioRanking.diaLibre:
        return 'Día libre';
      case TipoPremioRanking.reconocimiento:
        return 'Reconocimiento';
      case TipoPremioRanking.otro:
        return 'Otro';
    }
  }
}
