/// Enum SQL `tipo_reporte_insumo` (`0001_esquema_inicial.sql`).
enum TipoReporteInsumo {
  danado,
  agotado,
  perdido,
  usado;

  static TipoReporteInsumo desdeTexto(String texto) {
    switch (texto) {
      case 'danado':
        return TipoReporteInsumo.danado;
      case 'agotado':
        return TipoReporteInsumo.agotado;
      case 'perdido':
        return TipoReporteInsumo.perdido;
      case 'usado':
        return TipoReporteInsumo.usado;
      default:
        return TipoReporteInsumo.perdido;
    }
  }

  String aTexto() {
    switch (this) {
      case TipoReporteInsumo.danado:
        return 'danado';
      case TipoReporteInsumo.agotado:
        return 'agotado';
      case TipoReporteInsumo.perdido:
        return 'perdido';
      case TipoReporteInsumo.usado:
        return 'usado';
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoReporteInsumo.danado:
        return 'Dañado';
      case TipoReporteInsumo.agotado:
        return 'Agotado';
      case TipoReporteInsumo.perdido:
        return 'Perdido';
      case TipoReporteInsumo.usado:
        return 'Usado';
    }
  }
}