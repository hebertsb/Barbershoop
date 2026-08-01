enum TipoReporteInsumo {
  usado,
  perdido,
  danado;

  static TipoReporteInsumo desdeTexto(String texto) {
    switch (texto) {
      case 'usado':
        return TipoReporteInsumo.usado;
      case 'perdido':
        return TipoReporteInsumo.perdido;
      case 'danado':
        return TipoReporteInsumo.danado;
      default:
        return TipoReporteInsumo.usado;
    }
  }

  String aTexto() {
    switch (this) {
      case TipoReporteInsumo.usado:
        return 'usado';
      case TipoReporteInsumo.perdido:
        return 'perdido';
      case TipoReporteInsumo.danado:
        return 'danado';
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoReporteInsumo.usado:
        return 'Usado';
      case TipoReporteInsumo.perdido:
        return 'Perdido';
      case TipoReporteInsumo.danado:
        return 'Dañado';
    }
  }
}
